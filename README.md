# 🚀 IggyCloud

**Cloud-Native eShop Deployment & Testing Resources**

IggyCloud is a comprehensive collection of cloud deployment tools and resources for the .NET eShop reference application. It provides everything you need to deploy, test, and monitor the eShop application in Kubernetes environments with enterprise-grade tooling.

## 🎯 What is IggyCloud?

IggyCloud transforms the Microsoft eShop reference application into a production-ready, cloud-native solution by providing:

- **Kubernetes Deployment**: Complete K8s manifests and deployment automation
- **Container Orchestration**: Aspirate-powered container generation and deployment
- **Load Testing**: Comprehensive k6 testing suite with monitoring
- **Observability**: Integrated Grafana + Prometheus monitoring stack

## 📦 Current Features

### 🏗️ Deployment Tools

- **Aspirate Integration**: Automated .NET Aspire to Kubernetes deployment
- **Docker Desktop Ready**: Optimized for local development with docker-desktop context
- **Authentication Simplified**: Mock authentication setup for streamlined testing
- **Database Management**: PostgreSQL with pgvector extension support

### 🧪 Load Testing Suite

- **k6 Performance Tests**: High-throughput load testing scenarios
- **Real-time Monitoring**: Grafana dashboards with live metrics
- **Scalable Testing**: Support for 500-700 concurrent virtual users
- **API Coverage**: Comprehensive catalog API testing

### ☸️ Kubernetes Resources

- **Production-Ready Manifests**: Complete K8s deployment configurations
- **Service Mesh Ready**: Prepared for advanced networking scenarios
- **Persistent Storage**: Database persistence with volume management
- **Health Checks**: Comprehensive readiness and liveness probes

## 🚀 Quick Start

### Prerequisites
- Docker Desktop with Kubernetes enabled
- .NET 9 SDK
- kubectl configured for docker-desktop

### Deploy eShop to Kubernetes
```bash
cd aspir8/
./Aspir8.sh
```

### Run Performance Tests
```bash
cd k6/
./deploy.sh    # Deploy monitoring stack
./run-test.sh  # Execute load tests
```

### Access Applications
- **eShop Web App**: http://localhost:30509
- **Grafana Dashboard**: http://localhost:30300 (admin/admin123)
- **Prometheus**: http://localhost:30090

## 📊 Architecture

IggyCloud deploys a complete microservices architecture:

- **Frontend**: Web application and mobile BFF
- **APIs**: Catalog, Basket, Ordering, Webhooks, Payment services
- **Data Layer**: PostgreSQL with Redis caching
- **Messaging**: RabbitMQ event bus
- **Monitoring**: Aspire Dashboard, Grafana, Prometheus

## 🛣️ IggyCloud Journey

### 🎯 Core Mission
IggyCloud is focused on pushing cloud-native .NET applications to their limits through:

- **.NET Aspire** – Control Panel & Observability for modern cloud apps
- **Aspirate** – Seamless deployment to local Kubernetes clusters  
- **Performance Testing** – Push the system until it breaks 💥
- **Deep Observability** – Really understand what's happening inside your apps
- **Scaling & Bottlenecks** – Handle growth and squeeze out maximum performance

### ✅ Current Capabilities
- **Kubernetes Deployment**: Complete Aspirate-powered K8s deployment
- **Load Testing Suite**: k6 performance tests with Grafana monitoring
- **Observability Stack**: Integrated Prometheus + Grafana dashboards
- **Mock Authentication**: Simplified auth for streamlined testing

### 🚀 Upcoming Focus Areas
- **Enhanced Performance Testing**: Comprehensive stress testing across all microservices
- **Advanced Observability**: Deep-dive monitoring and performance analytics
- **Scaling Strategies**: Auto-scaling and load balancing optimizations
- **Bottleneck Analysis**: Identify and resolve performance constraints
- **Chaos Engineering**: Resilience testing under failure conditions

> **Note**: This roadmap focuses on IggyCloud's cloud deployment and performance testing mission. For the underlying eShop application roadmap, refer to the [official Microsoft eShop repository](https://github.com/dotnet/eShop).

## 🤝 Contributing

Contributions are welcome! Whether it's improving deployment scripts, adding new test scenarios, or enhancing documentation, your input helps make IggyCloud better for everyone.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📜 License

This project follows the same licensing as the parent eShop project. See [LICENSE](LICENSE) for details.

---

**Built with ❤️ for the cloud-native community**