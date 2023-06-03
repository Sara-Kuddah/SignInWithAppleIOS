/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import SwiftUI
import AuthenticationServices

struct ContentView: View {
  @Environment(\.window) var window: UIWindow?
  @State var appleSignInDelegates: SignInWithAppleDelegates! = nil
  @State private var showingAlert = false
  @State private var alertMessage = ""
  @State private var alertTitle = ""

  var body: some View {
    ZStack {
      Color.green.edgesIgnoringSafeArea(.all)

      VStack {
        Image("razeware")

          .frame(width: 280, height: 60)
          .onTapGesture(perform: showAppleLogin)
      }
      .alert(isPresented: $showingAlert) {
        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("Okay!")))
      }
    }
  }

  private func showAppleLogin() {
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]

    performSignIn(using: [request])
  }

  private func performSignIn(using requests: [ASAuthorizationRequest]) {
    appleSignInDelegates = SignInWithAppleDelegates(window: window) { success in
      switch success {
      case .success(let profile): self.showProfileAlert(profile: profile)
      case .failure(let error): self.showErrorAlert(error: error)
      }
    }

    let controller = ASAuthorizationController(authorizationRequests: requests)
    controller.delegate = appleSignInDelegates
    controller.presentationContextProvider = appleSignInDelegates

    controller.performRequests()
  }

  private func showErrorAlert(error: Error) {
    self.showingAlert = true
    self.alertTitle = "Error 😐"
    self.alertMessage = error.localizedDescription
  }

  private func showProfileAlert(profile: UserProfile) {
    self.showingAlert = true
    self.alertTitle = "Success 🎉"
    self.alertMessage = """
      User ID: \(profile.id)
      Email: \(profile.email)
      First name: \(profile.firstName ?? "N/A")
      Last name: \(profile.lastName ?? "N/A")
    """
  }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif
