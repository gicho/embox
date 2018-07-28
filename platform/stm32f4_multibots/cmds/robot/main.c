/**
 * @file
 * @brief
 *
 * @date 11.01.2017
 * @author Alex Kalmuk
 */

#include <errno.h>
#include <stdio.h>
#include <unistd.h>

#include <util/log.h>
#include <kernel/thread.h>

#include <libs/nrf24.h>
#include <libs/gy_30.h>
#include <libs/stepper_motor.h>

static void init_leds() {
	BSP_LED_Init(LED3);
	BSP_LED_Init(LED4);
	BSP_LED_Init(LED5);
	BSP_LED_Init(LED6);
}

static void *light_sensor_loop(void *arg) {
	uint16_t level;

	while (1) {
		level = gy_30_read_light_level();
		printf("light (lx): %d\n", level);
		sleep(1);
	}

	return NULL;
}

static void robot_config_nrf24(uint8_t *tx_addr, uint8_t *rx_addr,
								uint8_t chan, int payload_len) {
	nrf24_init();
	nrf24_config(chan, payload_len);

	nrf24_rx_address(rx_addr);
	nrf24_tx_address(tx_addr);

	nrf24_powerUpRx();
}

static void robot_config_motors(struct stepper_motor *motor1,
								struct stepper_motor *motor2) {
	motor_init(motor1, GPIO_PIN_0, GPIO_PIN_2, GPIO_PIN_4, GPIO_PIN_6, GPIOD);
	motor_init(motor2, GPIO_PIN_8, GPIO_PIN_10, GPIO_PIN_12, GPIO_PIN_14, GPIOE);
	motor_set_speed(motor1, MOTOR_MAX_SPEED);
	motor_set_speed(motor2, MOTOR_MAX_SPEED);
}

static int robot_config_gy_30(int i2c_nr, int mode) {
	if (gy_30_init(i2c_nr) < 0) {
		log_error("gy_30_init failed\n");
		return -1;
	}

	gy_30_setup_mode(mode);

	return 0;
}

static void main_loop(void) {
	struct thread *th;
	struct stepper_motor motor1, motor2;
	uint8_t tx_addr[5] = {0xAA,0xBB,0xCC,0xDD,0x01};
	uint8_t rx_addr[5] = {0xEE,0xFF,0xAA,0xBB,0x02};
	int const i2c_nr = 1;

	/* TODO Each robot must set it's own rx and tx address */
	robot_config_nrf24(tx_addr, rx_addr, 96, 8);
	printf("NRF24L01+ radio module configured\n");

	robot_config_motors(&motor1, &motor2);
	printf("Stepper motors configured\n");

	if (robot_config_gy_30(i2c_nr, BH1750_CONTINUOUS_HIGH_RES_MODE) < 0) {
		printf("GY-30 initialization failed\n");
		return;
	}
	printf("GY-30 configured\n");

#if 0
	ir_init();
	ir_enable();
	HAL_GPIO_WritePin(IR_GPIO, IR_LED_PIN, GPIO_PIN_SET);
#endif

	th = thread_create(THREAD_FLAG_SUSPENDED, light_sensor_loop, NULL);
	if (!th) {
		log_error("Failed to create thread\n");
		return;
	}
	if (thread_launch(th) != 0) {
		log_error("Failed to launch thread\n");
		return;
	}
	if (thread_detach(th) != 0) {
		log_error("Failed to detach thread\n");
		return;
	}

	while (1) {
		motor_do_steps2(&motor1, &motor2, 2 * MOTOR_STEPS_PER_REVOLUTION, MOTOR_RUN_BACKWARD);
		usleep(500000);
	}
}

int main(int argc, char *argv[]) {
	printf("Robot test start!\n");

	init_leds();
	BSP_LED_Toggle(LED6);

	main_loop();

	return 0;
}
