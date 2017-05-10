DROP TABLE vpcs;
DROP TABLE subnets;
DROP TABLE instances;
CREATE TABLE "vpcs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "vid" VARCHAR(50), "name" VARCHAR(50), "cidr_block" VARCHAR(50), "state" VARCHAR(50), "resource_json" TEXT);
CREATE TABLE "subnets" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "sid" VARCHAR(50), "name" VARCHAR(50), "cidr_block" VARCHAR(50), "vpc_id" VARCHAR(50), "availability_zone" VARCHAR(50), "available_ip_address_count" VARCHAR(50), "resource_json" TEXT);
CREATE TABLE "instances" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "iid" VARCHAR(50), "name" VARCHAR(50), "instance_type" VARCHAR(50), "private_ip_address" VARCHAR(50), "public_ip_address" VARCHAR(50), "vpc_id" VARCHAR(50), "subnet_id" VARCHAR(50), "state" VARCHAR(50), "resource_json" TEXT);
