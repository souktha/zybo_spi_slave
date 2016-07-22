/*
 * A SPI driver for slave device 5a
 *
 * Copyright (c) 2016, Soukthavy Sopha <soukthavy@yahoo.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 */

#include <linux/delay.h>
#include <linux/err.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/spi/spi.h>
#include <linux/types.h>

struct spi5a_dev {
	struct device *dev;
	void *buf;
	int id;
};
static int spi5a_probe(struct spi_device *spi)
{
	int ret=0;

	spi->bits_per_word = 8;
    	spi_setup(spi);

	printk(KERN_INFO "spi read ID for cs %d, mode %d, bpw %d\n",spi->chip_select,spi->mode,spi->bits_per_word);
	ret = spi_w8r8(spi, 0x1d); //read ID

	if (ret < 0) {
		dev_err(&spi->dev, "not found.\n");
		printk(KERN_INFO "spi read id return 0x%x\n",ret);
		return ret;
	}
	printk(KERN_INFO "%s returns id= 0x%x\n",__FUNCTION__,(u8)ret);

	ret = spi_w8r8(spi, 0xea); //read 
	printk(KERN_INFO "%s read(ea) returns 0x%x\n",__FUNCTION__,(u8)ret);

	return 0;
}

static int spi5a_remove(struct spi_device *spi)
{
	return 0;
}

static struct spi_driver spi5a_driver = {
	.driver = {
		.name	= "spi5a",
	},
	.probe	= spi5a_probe,
	.remove = spi5a_remove,
};

module_spi_driver(spi5a_driver);

MODULE_DESCRIPTION("spi5a simple driver");
MODULE_AUTHOR("Soukthavy Sopha <soukthavy@yahoo.com>");
MODULE_LICENSE("GPL");
