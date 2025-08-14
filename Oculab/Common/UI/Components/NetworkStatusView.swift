//
//  NetworkStatusView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import SwiftUI
import Network

/// A view that displays the current network connection status
struct NetworkStatusView: View {
    @StateObject private var retryManager = DependencyInjection.shared.networkRetryManager
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Network Status Indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: AppConstants.animationDuration), value: retryManager.isConnected)
            
            // Status Text
            Text(statusText)
                .font(AppTypography.p4)
                .foregroundColor(AppColors.slate600)
            
            // Connection Type (if connected)
            if retryManager.isConnected {
                connectionTypeIcon
                    .font(AppTypography.p5)
                    .foregroundColor(AppColors.slate500)
            }
        }
        .padding(.horizontal, AppConstants.defaultPadding * 0.75)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius + 4)
                .fill(AppColors.slate50)
        )
        .onTapGesture {
            showingDetails.toggle()
        }
        .sheet(isPresented: $showingDetails) {
            NetworkDetailsView(retryManager: retryManager)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        retryManager.isConnected ? AppColors.green500 : AppColors.red500
    }
    
    private var statusText: String {
        retryManager.isConnected ? AppNetwork.connected : AppNetwork.noConnection
    }
    
    @ViewBuilder
    private var connectionTypeIcon: some View {
        switch retryManager.connectionType {
        case .wifi:
            Image(systemName: AppNetworkIcon.wifi)
        case .cellular:
            Image(systemName: AppNetworkIcon.antennaRadiowaves)
        case .ethernet:
            Image(systemName: AppNetworkIcon.cableConnector)
        case .unknown:
            Image(systemName: AppNetworkIcon.network)
        }
    }
}

// MARK: - Network Details Sheet

struct NetworkDetailsView: View {
    @ObservedObject var retryManager: NetworkRetryManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppNetwork.connectionStatus)
                        .font(AppTypography.s4)
                        .foregroundColor(AppColors.slate900)
                    
                    HStack {
                        Circle()
                            .fill(retryManager.isConnected ? AppColors.green500 : AppColors.red500)
                            .frame(width: 12, height: 12)
                        
                        Text(retryManager.isConnected ? AppNetwork.connected : AppNetwork.disconnected)
                            .font(AppTypography.p2)
                            .foregroundColor(AppColors.slate800)
                    }
                    
                    if retryManager.isConnected {
                        HStack {
                            connectionTypeIcon
                                .font(AppTypography.p3)
                                .foregroundColor(AppColors.purple500)
                            Text(connectionTypeDescription)
                                .font(AppTypography.p2)
                                .foregroundColor(AppColors.slate600)
                        }
                    }
                }
                
                Divider()
                    .background(AppColors.slate200)
                
                // Network Quality Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppNetwork.Tips.title)
                        .font(AppTypography.s4)
                        .foregroundColor(AppColors.slate900)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        tipRow(
                            icon: AppNetworkIcon.wifi,
                            text: AppNetwork.Tips.wifi
                        )
                        
                        tipRow(
                            icon: AppNetworkIcon.antennaRadiowaves,
                            text: AppNetwork.Tips.cellular
                        )
                        
                        tipRow(
                            icon: AppNetworkIcon.arrowClockwise,
                            text: AppNetwork.Tips.retry
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(AppNetwork.status)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppAction.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var connectionTypeIcon: some View {
        switch retryManager.connectionType {
        case .wifi:
            Image(systemName: AppNetworkIcon.wifi)
        case .cellular:
            Image(systemName: AppNetworkIcon.antennaRadiowaves)
        case .ethernet:
            Image(systemName: AppNetworkIcon.cableConnector)
        case .unknown:
            Image(systemName: AppNetworkIcon.network)
        }
    }
    
    private var connectionTypeDescription: String {
        switch retryManager.connectionType {
        case .wifi:
            return AppNetwork.ConnectionType.wifi
        case .cellular:
            return AppNetwork.ConnectionType.cellular
        case .ethernet:
            return AppNetwork.ConnectionType.ethernet
        case .unknown:
            return AppNetwork.ConnectionType.unknown
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.purple500)
                .font(AppTypography.p3)
                .frame(width: 20)
            
            Text(text)
                .font(AppTypography.p3)
                .foregroundColor(AppColors.slate600)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Compact Network Status (for smaller spaces)

struct CompactNetworkStatusView: View {
    @StateObject private var retryManager = DependencyInjection.shared.networkRetryManager
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(retryManager.isConnected ? AppColors.green500 : AppColors.red500)
                .frame(width: 6, height: 6)
            
            connectionTypeIcon
                .font(AppTypography.p5)
                .foregroundColor(AppColors.slate500)
        }
        .opacity(retryManager.isConnected ? 0.7 : 1.0)
        .animation(.easeInOut(duration: AppConstants.animationDuration), value: retryManager.isConnected)
    }
    
    @ViewBuilder
    private var connectionTypeIcon: some View {
        switch retryManager.connectionType {
        case .wifi:
            Image(systemName: AppNetworkIcon.wifi)
        case .cellular:
            Image(systemName: AppNetworkIcon.antennaRadiowaves)
        case .ethernet:
            Image(systemName: AppNetworkIcon.cableConnector)
        case .unknown:
            Image(systemName: AppNetworkIcon.network)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        NetworkStatusView()
        CompactNetworkStatusView()
    }
    .padding(AppConstants.defaultPadding)
}
