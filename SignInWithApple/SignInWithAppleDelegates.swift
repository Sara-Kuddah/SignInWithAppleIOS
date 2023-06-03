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
import AuthenticationServices
import Contacts

class SignInWithAppleDelegates: NSObject {
  private let signInSucceeded: (Result<UserProfile, Error>) -> Void
  private weak var window: UIWindow!

  init(window: UIWindow?, onSignedIn: @escaping (Result<UserProfile, Error>) -> Void) {
    self.window = window
    self.signInSucceeded = onSignedIn
  }
}

extension SignInWithAppleDelegates: ASAuthorizationControllerDelegate {
  private func authorizeWithSIWA(credential: ASAuthorizationAppleIDCredential) {
    WebAPI.authorizeUsingSIWA(
      identityToken: credential.identityToken,
      email: credential.email,
      firstName: credential.fullName?.givenName,
      lastName: credential.fullName?.familyName,
      completion: { result in
        switch result {
        case .success: self.getProfile()
        case .failure(let error): self.signInSucceeded(.failure(error))
        }
      })
  }

  private func getProfile() {
    WebAPI.getProfile { result in
      switch result {
      case .success(let profile): self.signInSucceeded(.success(profile))
      case .failure(let error): self.signInSucceeded(.failure(error))
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let appleIdCredential as ASAuthorizationAppleIDCredential:
      authorizeWithSIWA(credential: appleIdCredential)
    default:
      break
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    self.signInSucceeded(.failure(error))
  }
}

extension SignInWithAppleDelegates: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.window
  }
}
