//
//  ContentView.swift
//  DemoProject
//
//  Created by Ankush Kushwaha on 21/01/25.
//

import SwiftUI
import lib_sso_authentication_ios

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if let token = viewModel.accessToken {
                Text("Access Token:")
                    .font(.headline)
                Text(token)
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding()
                
            } else if let error = viewModel.errorMessage {
                Text("Error:")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
            }

            let isLoginNeeded = viewModel.accessToken == nil
            
            Button(action: {
                viewModel.isPresentedLogin = true
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!isLoginNeeded)
            .opacity(isLoginNeeded ? 1.0 : 0.6)
            .sheet(isPresented: $viewModel.isPresentedLogin) {
                LoginUIView(viewModel: viewModel)
            }
            
            Button(action: {
                viewModel.isPresentedLogout = true
            }) {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoginNeeded)
            .opacity(!isLoginNeeded ? 1.0 : 0.6)
            .sheet(isPresented: $viewModel.isPresentedLogout) {
                LogoutUIView(viewModel: viewModel)
            }
        }
        .padding()
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                }
            }
        )
    }
}


struct LogoutUIView: UIViewControllerRepresentable {
    let viewModel: AuthViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            viewModel.logout(viewController: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct LoginUIView: UIViewControllerRepresentable {
    let viewModel: AuthViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            viewModel.login(from: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    ContentView()
}
