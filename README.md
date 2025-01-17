# Lightweight Publish-Subscribe Application Protocol

This project involves the design and implementation of a lightweight publish-subscribe application protocol using TinyOS. The protocol is inspired by MQTT and has been tested through simulations on a star-shaped network topology. The network comprises 8 client nodes connected to a PAN coordinator, which acts as the central broker (similar to an MQTT broker).

## Key Features
- **Publish-Subscribe Communication**: Implements a lightweight protocol for efficient data exchange between nodes and the broker.
- **Star-Shaped Network Topology**: Designed and tested on a topology where all client nodes communicate through a central PAN coordinator.
- **Simulation Testing**: Validated through simulations using Tossim and Cooja.
- **Integration with IoT Platforms**: Data from the network is visualized using Node-RED and ThingSpeak.

## How It Works
1. **Client Nodes**: Each node can publish data to the PAN coordinator or subscribe to specific topics to receive data.
2. **PAN Coordinator**: Acts as a broker, managing topic subscriptions and distributing messages to subscribed nodes.
3. **Star Topology**: Ensures efficient communication, with the PAN coordinator serving as the hub for all messages.
4. **Simulation Environment**:
   - **Tossim**: Used for simulating TinyOS-based networks.
   - **Cooja**: Employed for running detailed network simulations.
5. **IoT Data Visualization**:
   - **Node-RED**: Provides a dashboard for real-time data monitoring.
   - **ThingSpeak**: Offers cloud-based data storage and visualization.

## Technologies Used
- **TinyOS**: Operating system for the implementation of the protocol.
- **Tossim**: Simulation tool for TinyOS applications.
- **Cooja**: Network simulator for validating the protocol.
- **JavaScript**: Used for scripting and enhancing IoT visualizations.
- **Node-RED**: For creating IoT dashboards and workflows.
- **ThingSpeak**: For cloud-based data visualization and analysis.

## Applications
- **IoT Networks**: Ideal for lightweight IoT applications requiring efficient message distribution.
- **Sensor Networks**: Suitable for monitoring and controlling sensor networks in constrained environments.
- **Data Aggregation**: Serves as a lightweight alternative to MQTT for simple data aggregation systems.

## Future Enhancements
- Implement security features like encryption for message transmission.
- Extend support for dynamic node addition and removal in the network.
- Test scalability with larger network topologies.
- Optimize performance for energy-constrained devices.

## Contact
Feel free to reach out if you have questions or suggestions about this project.
