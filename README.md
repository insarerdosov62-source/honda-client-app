# Honda Service Management System

A robust, real-time maintenance tracking ecosystem designed to bridge the operational gap between automotive service centers and vehicle owners. 

## 🚀 Project Overview
This project addresses the challenge of transparency and efficiency in vehicle maintenance. It consists of two synchronized applications that allow for seamless data management and instant client updates.

* **Customer Application (Flutter):** A cross-platform mobile solution for car owners to view their service history, manage profile information, and receive real-time updates on maintenance status.
* **Service Admin Panel (Kotlin):** A native Android administration tool for service staff to input and manage maintenance records, ensuring data integrity and quick service logging.

## 🛠 Technical Stack
* **Frontend (Client):** Flutter (Dart)
* **Frontend (Admin):** Kotlin (Native Android)
* **Backend:** Firebase (Realtime Database & Cloud Functions)

## 💡 Key Engineering Highlights
* **Real-time Synchronization:** Built a low-latency data pipeline between the Admin Panel and the Customer App using Firebase, ensuring that any record update is instantly reflected on the client side.
* **Event-Driven Notifications:** Implemented an automated trigger system that pushes service updates directly to the user, enhancing the user experience and service transparency.
* **System Architecture:** Designed a scalable two-tier architecture that decouples service administration from customer data consumption.

## 📈 Future Roadmap
* Integration of advanced analytics for maintenance cost tracking.
* AI-driven maintenance scheduling based on vehicle usage patterns.
* Integration of Google Maps for service center navigation.
