/*
 * slub_host_neg.c —— 负向用例（重复释放 / 非法指针 / 非对齐指针）
 *
 * 契约：这些误用在正常构建下触发 panic（slub.h 明确不承诺静默处理），
 * 因此每个用例放在 fork() 出的子进程里执行，父进程等待并校验子进程确实
 * 异常终止（abort/信号），从而“预期 panic 不中止正常测试集”。
 *
 * 需要 -DSLUB_DEBUG 以启用小对象的重复释放诊断（slub_check_ptr）。
 * 这些用例独立于 SLUB_TEST_PASS 判定之外，单独打印 SLUB_NEG_PASS /
 * SLUB_NEG_FAIL 供 tools/host/run_all.sh 检查。
 *
 * 用法：./slub_host_neg
 */

#include <slub.h>
#include <slub_port.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static int neg_failures;

/* slub_host_port.c 提供 */
void slub_host_bind_cpu(unsigned int cpu);

/* 在子进程里执行会 panic 的误用；父进程校验其非正常退出且带 panic 输出 */
static void run_neg(const char *name, void (*misuse)(void)) {
    int pipefd[2];
    pid_t pid;
    int status = 0;
    char buf[512];
    ssize_t n;
    int panicked = 0, abnormal = 0;

    if (pipe(pipefd) != 0) {
        printf("SLUB_NEG_FAIL case=%s why=pipe failed\n", name);
        neg_failures++;
        return;
    }
    pid = fork();
    if (pid < 0) {
        printf("SLUB_NEG_FAIL case=%s why=fork failed\n", name);
        neg_failures++;
        close(pipefd[0]);
        close(pipefd[1]);
        return;
    }
    if (pid == 0) {
        /* 子进程：stderr 走管道，父进程检查 panic 文本 */
        close(pipefd[0]);
        dup2(pipefd[1], 2);
        close(pipefd[1]);
        misuse();
        /* 若误用没有触发 panic（诊断缺失），显式非零退出 */
        _exit(42);
    }

    close(pipefd[1]);
    buf[0] = '\0';
    while ((n = read(pipefd[0], buf + strlen(buf),
                     sizeof(buf) - strlen(buf) - 1)) > 0) {
        buf[strlen(buf)] = '\0';
    }
    close(pipefd[0]);
    waitpid(pid, &status, 0);

    panicked = strstr(buf, "panic") != NULL;
    abnormal = !WIFEXITED(status) || WEXITSTATUS(status) != 0;

    if (abnormal && (panicked || WEXITSTATUS(status) == 42)) {
        if (panicked) {
            printf("SLUB_NEG_CASE %s PASS (panicked as contracted)\n", name);
        } else {
            printf("SLUB_NEG_CASE %s FAIL: exited without panic text "
                   "(diagnostic missing)\n",
                   name);
            neg_failures++;
        }
    } else {
        printf("SLUB_NEG_CASE %s FAIL: child exited normally (status=%d) "
               "— misuse not diagnosed\n",
               name, WIFEXITED(status) ? WEXITSTATUS(status) : -1);
        neg_failures++;
    }
}

/* ---------------- 具体误用 ---------------- */

static char foreign_buf[64] __attribute__((aligned(16))); /* 不在页池内 */

static void misuse_double_free_small(void) {
    void *p = kmalloc(64);
    if (p == NULL) _exit(0);
    kfree(p);
    kfree(p); /* 第二次释放必须被诊断 */
}

static void misuse_double_free_large(void) {
    void *p = kmalloc(8192);
    if (p == NULL) _exit(0);
    kfree(p);
    kfree(p); /* 大对象魔数已清零，必须被诊断 */
}

static void misuse_foreign_pointer(void) {
    kfree(foreign_buf); /* 非本分配器指针 */
}

static void misuse_misaligned(void) {
    void *p = kmalloc(64);
    if (p == NULL) _exit(0);
    kfree((char *)p + 8); /* 非 16 字节对齐 */
}

int main(void) {
    slub_host_bind_cpu(0);
    slub_init();

    printf("SLUB_NEG_BEGIN (double free / foreign / misaligned are panics by "
           "contract)\n");
    run_neg("double_free_small", misuse_double_free_small);
    run_neg("double_free_large", misuse_double_free_large);
    run_neg("foreign_pointer", misuse_foreign_pointer);
    run_neg("misaligned_pointer", misuse_misaligned);

    if (neg_failures) {
        printf("SLUB_NEG_FAIL total=%d\n", neg_failures);
        return 1;
    }
    printf("SLUB_NEG_PASS\n");
    return 0;
}
