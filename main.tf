provider "aws" {
  version = "4.6.0"
  region = "us-east-2"
}

resource "aws_vpc" "DS_VPC" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "DroneShuttle-VPC"
  }
}
////////////////////AWS IGW////////////////////////
resource "aws_internet_gateway" "DS_IGW" {
  vpc_id = aws_vpc.DS_VPC.id
}
////////////////////AWS SUBNET////////////////////////
resource "aws_subnet" "DS_Public_Subnet_1" {
  vpc_id     = aws_vpc.DS_VPC.id
  cidr_block = "10.0.1.0/24"
}
resource "aws_subnet" "DS_Public_Subnet_2" {
  vpc_id     = aws_vpc.DS_VPC.id
  cidr_block = "10.0.2.0/24"
}
resource "aws_subnet" "DS_App_Subnet_1" {
  vpc_id     = aws_vpc.DS_VPC.id
  cidr_block = "10.0.3.0/24"
}
resource "aws_subnet" "DS_App_Subnet_2" {
  vpc_id     = aws_vpc.DS_VPC.id
  cidr_block = "10.0.4.0/24"
}
resource "aws_subnet" "DS_Data_Subnet_1" {
  vpc_id     = aws_vpc.DS_VPC.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-2a"
}
resource "aws_subnet" "DS_Data_Subnet_2" {
  vpc_id     = aws_vpc.DS_VPC.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-2b"
}
////////////////////AWS Route Table ////////////////////////
resource "aws_route_table" "DS_PublicRT" {
  vpc_id = aws_vpc.DS_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.DS_IGW.id
  }

}
////////////////////AWS PUBLIC RT ASSOCIATION////////////////////////
resource "aws_route_table_association" "DS_RT_Public_Association_1" {
  subnet_id      = aws_subnet.DS_Public_Subnet_1.id
  route_table_id = aws_route_table.DS_PublicRT.id
}
resource "aws_route_table_association" "DS_RT_Public_Association_2" {
  subnet_id     = aws_subnet.DS_Public_Subnet_2.id
  route_table_id = aws_route_table.DS_PublicRT.id
}
////////////////////AWS PRIVATE RT 1 //////////////////////////////////
resource "aws_route_table" "DS_PrivateRT_1" {
  vpc_id = aws_vpc.DS_VPC.id

}
////////////////////AWS PRIVATE RT ASSOCIATION 1 /////////////////////
resource "aws_route_table_association" "DS_RT_Private_Association_1a" {
  subnet_id     = aws_subnet.DS_App_Subnet_1.id
  route_table_id = aws_route_table.DS_PrivateRT_1.id
}

////////////////////AWS PRIVATE RT ASSOCIATION 2 /////////////////////
resource "aws_route_table_association" "DS_RT_Private_Association_1-2a" {
  subnet_id     = aws_subnet.DS_Data_Subnet_1.id
  route_table_id = aws_route_table.DS_PrivateRT_1.id
}


////////////////////AWS PRIVATE RT 2 //////////////////////////////////
resource "aws_route_table" "DS_PrivateRT_2" {
  vpc_id = aws_vpc.DS_VPC.id

}

////////////////////AWS PRIVATE RT ASSOCIATION 1 /////////////////////
resource "aws_route_table_association" "DS_RT_Private_Association_1b" {
  subnet_id     = aws_subnet.DS_App_Subnet_2.id
  route_table_id = aws_route_table.DS_PrivateRT_2.id
}

////////////////////AWS PRIVATE RT ASSOCIATION 2 /////////////////////
resource "aws_route_table_association" "DS_RT_Private_Association_2b" {
  subnet_id     = aws_subnet.DS_Data_Subnet_2.id
  route_table_id = aws_route_table.DS_PrivateRT_2.id
}

////////////////////AWS Eip 1/////////////////////
resource "aws_eip" "DS_eip_1" {

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.DS_IGW]
}
////////////////////AWS Eip 2/////////////////////
resource "aws_eip" "DS_eip_2" {

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.DS_IGW]
}
///////////////AWS Nat gateway 1 ////////////////////
resource "aws_nat_gateway" "DS_Nat_gateway_1" {
  subnet_id     = aws_subnet.DS_Public_Subnet_1.id
  allocation_id = aws_eip.DS_eip_1.id

  tags = {
    Name = "gw NAT 1"
  }

}
///////////////AWS Nat gateway 2 ////////////////////
resource "aws_nat_gateway" "DS_Nat_gateway_2" {
  subnet_id     = aws_subnet.DS_Public_Subnet_2.id
  allocation_id = aws_eip.DS_eip_2.id

  tags = {
    Name = "gw NAT 2"
  }

}

//////////security groups////////
resource "aws_security_group" "DS_SG_EC" {
  name        = "ElasticCacheSG"
  description = "Security Group allowing Elasti Cache to have internet traffic"
  vpc_id      = aws_vpc.DS_VPC.id

  ingress {
    description      = "."
    from_port        = 11211
    to_port          = 11211
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.DS_VPC.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
  ///EFS
  resource "aws_security_group" "DS_SG_EFS" {
  name        = "EFSMountTargetSecurityGroup"
  description = "Security Group allowing traffic between EFS Mount Targets and Amazon EC2 instances"
  vpc_id      = aws_vpc.DS_VPC.id

  ingress {
    description      = "."
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.DS_VPC.cidr_block]
  }
  ingress {
    description      = "."
    from_port        = 2049 
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.DS_VPC.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
///RDS
  resource "aws_security_group" "DS_SG_RDS" {
  name        = "RDSSecurityGroup"
  description = "Security Group allowing RDS instances to have internet traffic"
  vpc_id      = aws_vpc.DS_VPC.id

  ingress {
    description      = "."
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.DS_VPC.cidr_block]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
///WordPress
  resource "aws_security_group" "DS_SG_WPS" {
  name        = "Wordpress Servers Security Group"
  description = "Security Group allowing RDS instances to have internet traffic"
  vpc_id      = aws_vpc.DS_VPC.id

  ingress {
    description      = "."
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.DS_VPC.cidr_block]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
///App
  resource "aws_security_group" "DS_SG_App" {
  name        = "app Security Group"
  description = "Security Group allowing HTTP traffic for instances"
  vpc_id      = aws_vpc.DS_VPC.id

  ingress {
    description      = "."
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.DS_VPC.cidr_block]
  }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
//////////////////RDS Subnet group////////////////////////////
resource "aws_db_subnet_group" "DS_RDS_Subnet_Group" {
  name       = "database subnets"
  subnet_ids = [aws_subnet.DS_Data_Subnet_1.id, aws_subnet.DS_Data_Subnet_2.id]
  
}
/////
resource "aws_rds_cluster_instance" "DS_cluster_instances" {
  cluster_identifier = aws_rds_cluster.DS_cluster_identifier.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.DS_cluster_identifier.engine
  engine_version     = aws_rds_cluster.DS_cluster_identifier.engine_version
}

resource "aws_rds_cluster" "DS_cluster_identifier" {
  cluster_identifier = "cluster-test"
  availability_zones = ["us-east-2a", "us-east-2b"]
  database_name      = "mydb"
  master_username    = "test123"
  master_password    = "test12345"
  engine             = "aurora"
  engine_version     = "5.6.mysql_aurora.1.22.2"
  db_subnet_group_name = aws_db_subnet_group.DS_RDS_Subnet_Group.name

}
# resource "aws_db_cluster_snapshot" "snapshot" {
#   db_cluster_identifier          = aws_rds_cluster.DS_cluster_identifier.id
#   db_cluster_snapshot_identifier = "tf-20220330123554207600000001"

# https://www.ioconnectservices.com/insight/aws-with-terraform
# Michael Briggs3:47 PM
# https://www.youtube.com/watch?v=zTQ1kY8xsY8
# }
///////////////////Memcached////////////////////////////////////////////
resource "aws_elasticache_cluster" "DS_Memcached" {
  cluster_id           = "cachedb"
  engine               = "memcached"
  node_type            = "cache.m5.large"
  num_cache_nodes      = 2
  port                 = 11211
}


  
