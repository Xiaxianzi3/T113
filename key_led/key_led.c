#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>  // struct input_event

int main()
{
    int fd_key, fd_led;
    char led_state = 0; // 0=灭, 1=亮
    struct input_event ev;

    // 打开按键设备
    fd_key = open("/dev/input/event3", O_RDONLY);
    if (fd_key < 0) {
        perror("open key device error");
        return -1;
    }

    // 打开LED设备
    fd_led = open("/dev/led", O_RDWR);
    if (fd_led < 0) {
        perror("open led device error");
        close(fd_key);
        return -1;
    }

    printf("按下按键切换LED亮灭...\n");

    while (1) {
        ssize_t n = read(fd_key, &ev, sizeof(ev));
        if (n != sizeof(ev)) {
            perror("read key event error");
            continue;
        }

        // EV_KEY 表示按键事件
        if (ev.type == EV_KEY && ev.value == 1) { // 按下事件
            led_state = !led_state; // 状态翻转
            if (led_state) {
                char on = 0;  // 你的驱动可能用 0 表示亮
                write(fd_led, &on, 1);
                printf("LED: ON\n");
            } else {
                char off = 1; // 驱动可能用 1 表示灭
                write(fd_led, &off, 1);
                printf("LED: OFF\n");
            }
        }
    }

    close(fd_key);
    close(fd_led);
    return 0;
}
