# SIS-H Deployment

This repository contains the Docker Compose configuration and deployment setup for **SIS-H** (Sistema de Informação de Saúde), a comprehensive health information system designed for managing electronic medical records (EMR) and healthcare data.

## Overview

SIS-H is a multi-component application consisting of:

- **Frontend**: A Vue.js-based user interface (sis-h-core)
- **Backend API**: A PHP Laravel-based REST API (sis-h-api)
- **Database**: MySQL database for storing healthcare data
- **Gateway**: Nginx reverse proxy for routing and load balancing

This deployment configuration orchestrates all components using Docker Compose, providing a complete, containerized deployment solution.

## Architecture

The deployment consists of three main services:

### Gateway Service

- **Base**: Nginx 1.29.0 Alpine
- **Purpose**: Reverse proxy and static file serving
- **Includes**:
  - Frontend static files from `ghcr.io/misau-dis/sis-h-core:dev`
  - API files from `ghcr.io/misau-dis/sis-h-api:dev`
- **Port**: 80 (HTTP)

### API Service

- **Base**: PHP-FPM (sis-h-api:php-fpm)
- **Framework**: Laravel
- **Purpose**: Healthcare data management and business logic
- **Features**:
  - RESTful API endpoints
  - Health check endpoint (`/ping`)
  - Permission management system
  - Development environment configured

### Database Service

- **Engine**: MySQL 9.3
- **Purpose**: Persistent storage for healthcare records
- **Database**: `moz_emr_api`
- **Features**:
  - Health monitoring
  - Persistent volume storage

## Quick Start

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd sis-h-deploy
   ```

2. **Start the services**:

   ```bash
   docker compose up -d
   ```

3. **Access the application**:
   - Frontend: http://localhost

## Health Monitoring

Both the API and database services include health checks:

- **API**: PHP-FPM ping endpoint monitoring
- **Database**: MySQL ping monitoring with automatic restart policies

## Data Persistence

- Database data is persisted using Docker volumes (`db-data`)

## System time

- System time synchronization via `/etc/localtime` volume mounts across all containers
# sisrmed
