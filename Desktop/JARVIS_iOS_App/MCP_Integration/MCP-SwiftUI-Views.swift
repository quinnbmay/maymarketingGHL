// MARK: - MCP SwiftUI Views
// This file contains SwiftUI views for MCP server management

import SwiftUI
import Combine

// MARK: - Main Server Management View

struct MCPServerManagementView: View {
    @StateObject private var manager = MCPClientManager()
    @State private var showingAddServer = false
    @State private var selectedServer: MCPServerConnection?
    @State private var searchText = ""
    
    var filteredServers: [MCPServerConnection] {
        if searchText.isEmpty {
            return manager.servers
        } else {
            return manager.servers.filter { server in
                server.config.name.localizedCaseInsensitiveContains(searchText) ||
                (server.config.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredServers.isEmpty {
                    EmptyServerListView(showingAddServer: $showingAddServer)
                } else {
                    ServerListView(
                        servers: filteredServers,
                        selectedServer: $selectedServer,
                        manager: manager
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Search servers...")
            .navigationTitle("MCP Servers")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAddServer = true }) {
                        Label("Add Server", systemImage: "plus")
                    }
                    
                    Menu {
                        Button("Refresh All") {
                            Task {
                                await refreshAllServers()
                            }
                        }
                        
                        Button("Export Configuration") {
                            exportConfiguration()
                        }
                        
                        Button("Import Configuration") {
                            importConfiguration()
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddMCPServerView(manager: manager)
            }
            .sheet(item: $selectedServer) { server in
                ServerDetailView(server: server)
            }
        }
    }
    
    private func refreshAllServers() async {
        for server in manager.servers {
            try? await server.discoverCapabilities()
        }
    }
    
    private func exportConfiguration() {
        // Implementation for configuration export
    }
    
    private func importConfiguration() {
        // Implementation for configuration import
    }
}

// MARK: - Empty State View

struct EmptyServerListView: View {
    @Binding var showingAddServer: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No MCP Servers")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first MCP server to get started with AI tool integration")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingAddServer = true }) {
                Label("Add Server", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Server List View

struct ServerListView: View {
    let servers: [MCPServerConnection]
    @Binding var selectedServer: MCPServerConnection?
    let manager: MCPClientManager
    
    var body: some View {
        List {
            ForEach(servers) { server in
                ServerRowView(server: server)
                    .onTapGesture {
                        selectedServer = server
                    }
                    .contextMenu {
                        ServerContextMenu(server: server, manager: manager)
                    }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await manager.removeServer(servers[index].id)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Server Row View

struct ServerRowView: View {
    @ObservedObject var server: MCPServerConnection
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(server.config.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = server.config.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    ServerCapabilityBadge(
                        title: "Tools",
                        count: server.tools.count,
                        color: .blue
                    )
                    
                    ServerCapabilityBadge(
                        title: "Resources",
                        count: server.resources.count,
                        color: .green
                    )
                    
                    ServerCapabilityBadge(
                        title: "Prompts",
                        count: server.prompts.count,
                        color: .orange
                    )
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ConnectionStatusView(state: server.state)
                
                Text(transportTypeText(for: server.config.transport))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func transportTypeText(for transport: MCPServerConfig.TransportType) -> String {
        switch transport {
        case .webSocket:
            return "WebSocket"
        case .httpSSE:
            return "HTTP+SSE"
        case .stdio:
            return "Stdio"
        }
    }
}

// MARK: - Server Capability Badge

struct ServerCapabilityBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

// MARK: - Connection Status View

struct ConnectionStatusView: View {
    let state: MCPConnectionState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color(for: state))
                .frame(width: 8, height: 8)
            
            Text(text(for: state))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color(for: state))
        }
    }
    
    private func color(for state: MCPConnectionState) -> Color {
        switch state {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    private func text(for state: MCPConnectionState) -> String {
        switch state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .reconnecting:
            return "Reconnecting"
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        }
    }
}

// MARK: - Server Context Menu

struct ServerContextMenu: View {
    let server: MCPServerConnection
    let manager: MCPClientManager
    
    var body: some View {
        Button(action: {
            Task {
                try? await server.initialize()
            }
        }) {
            Label("Reconnect", systemImage: "arrow.clockwise")
        }
        .disabled(server.state == .connecting || server.state == .reconnecting)
        
        Button(action: {
            Task {
                try? await server.discoverCapabilities()
            }
        }) {
            Label("Refresh Capabilities", systemImage: "arrow.triangle.2.circlepath")
        }
        .disabled(server.state != .connected)
        
        Divider()
        
        Button(role: .destructive, action: {
            Task {
                await manager.removeServer(server.id)
            }
        }) {
            Label("Remove Server", systemImage: "trash")
        }
    }
}

// MARK: - Add Server View

struct AddMCPServerView: View {
    @Environment(\.dismiss) private var dismiss
    let manager: MCPClientManager
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedTransport = TransportSelection.webSocket
    @State private var url = ""
    @State private var authMethod = AuthMethodSelection.none
    @State private var apiKey = ""
    @State private var bearerToken = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    enum TransportSelection: String, CaseIterable {
        case webSocket = "WebSocket"
        case httpSSE = "HTTP+SSE"
        
        var systemImage: String {
            switch self {
            case .webSocket:
                return "network"
            case .httpSSE:
                return "globe"
            }
        }
    }
    
    enum AuthMethodSelection: String, CaseIterable {
        case none = "None"
        case apiKey = "API Key"
        case bearerToken = "Bearer Token"
        
        var systemImage: String {
            switch self {
            case .none:
                return "lock.open"
            case .apiKey:
                return "key"
            case .bearerToken:
                return "person.badge.key"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Information") {
                    TextField("Server Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Connection") {
                    Picker("Transport", selection: $selectedTransport) {
                        ForEach(TransportSelection.allCases, id: \.self) { transport in
                            Label(transport.rawValue, systemImage: transport.systemImage)
                                .tag(transport)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Server URL", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section("Authentication") {
                    Picker("Auth Method", selection: $authMethod) {
                        ForEach(AuthMethodSelection.allCases, id: \.self) { method in
                            Label(method.rawValue, systemImage: method.systemImage)
                                .tag(method)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    switch authMethod {
                    case .none:
                        EmptyView()
                    case .apiKey:
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    case .bearerToken:
                        SecureField("Bearer Token", text: $bearerToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add MCP Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await addServer()
                        }
                    }
                    .disabled(name.isEmpty || url.isEmpty || isLoading)
                }
            }
            .disabled(isLoading)
        }
    }
    
    private func addServer() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            // Validate URL
            guard let serverURL = URL(string: url) else {
                errorMessage = "Invalid URL format"
                return
            }
            
            // Create transport type
            let transportType: MCPServerConfig.TransportType
            switch selectedTransport {
            case .webSocket:
                transportType = .webSocket(serverURL)
            case .httpSSE:
                transportType = .httpSSE(serverURL)
            }
            
            // Create auth method
            let auth: MCPAuthenticationManager.AuthMethod?
            switch authMethod {
            case .none:
                auth = nil
            case .apiKey:
                auth = .apiKey(apiKey)
            case .bearerToken:
                auth = .bearerToken(bearerToken)
            }
            
            // Create server config
            let config = MCPServerConfig(
                name: name,
                description: description.isEmpty ? nil : description,
                transport: transportType,
                authMethod: auth,
                metadata: nil
            )
            
            // Add server
            _ = try await manager.addServer(config: config)
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Server Detail View

struct ServerDetailView: View {
    @ObservedObject var server: MCPServerConnection
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ServerInfoSection(server: server)
                
                if !server.tools.isEmpty {
                    ToolsSection(tools: server.tools)
                }
                
                if !server.resources.isEmpty {
                    ResourcesSection(resources: server.resources)
                }
                
                if !server.prompts.isEmpty {
                    PromptsSection(prompts: server.prompts)
                }
                
                ConnectionSection(server: server)
            }
            .navigationTitle(server.config.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Server Detail Sections

struct ServerInfoSection: View {
    let server: MCPServerConnection
    
    var body: some View {
        Section("Server Information") {
            if let description = server.config.description {
                Text(description)
                    .font(.body)
            }
            
            if let serverInfo = server.capabilities?.serverInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server: \(serverInfo.name)")
                        .font(.caption)
                    if let version = serverInfo.version {
                        Text("Version: \(version)")
                            .font(.caption)
                    }
                }
            }
            
            Text("Protocol: \(server.capabilities?.protocolVersion ?? "Unknown")")
                .font(.caption)
        }
    }
}

struct ToolsSection: View {
    let tools: [MCPTool]
    
    var body: some View {
        Section("Tools (\(tools.count))") {
            ForEach(tools, id: \.name) { tool in
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name)
                        .font(.headline)
                    Text(tool.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct ResourcesSection: View {
    let resources: [MCPResource]
    
    var body: some View {
        Section("Resources (\(resources.count))") {
            ForEach(resources, id: \.uri) { resource in
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.name)
                        .font(.headline)
                    Text(resource.uri)
                        .font(.caption)
                        .foregroundColor(.blue)
                    if let description = resource.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct PromptsSection: View {
    let prompts: [MCPPrompt]
    
    var body: some View {
        Section("Prompts (\(prompts.count))") {
            ForEach(prompts, id: \.name) { prompt in
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.name)
                        .font(.headline)
                    if let description = prompt.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let arguments = prompt.arguments, !arguments.isEmpty {
                        Text("Arguments: \(arguments.count)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct ConnectionSection: View {
    let server: MCPServerConnection
    
    var body: some View {
        Section("Connection") {
            HStack {
                Text("Status")
                Spacer()
                ConnectionStatusView(state: server.state)
            }
            
            HStack {
                Text("Transport")
                Spacer()
                Text(transportText(for: server.config.transport))
                    .foregroundColor(.secondary)
            }
            
            if case .webSocket(let url) = server.config.transport {
                HStack {
                    Text("URL")
                    Spacer()
                    Text(url.absoluteString)
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
    }
    
    private func transportText(for transport: MCPServerConfig.TransportType) -> String {
        switch transport {
        case .webSocket:
            return "WebSocket"
        case .httpSSE:
            return "HTTP+SSE"
        case .stdio:
            return "Stdio"
        }
    }
}