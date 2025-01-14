//
//  EnrolledCoursesViewController+Banner.swift
//  edX
//
//  Created by Saeed Bashir on 9/29/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

// if the app is open from the deep link, send banner get request after a delay
private let DeeplinkDelayTime: Double = 10

//Notics/Acquisition Banner handling
extension EnrolledCoursesViewController: BannerViewControllerDelegate {
    func handleBanner() {
        if !handleBannerOnStart || environment.session.currentUser == nil {
            return
        }

        // If the banner is already on screen don't send the banner request
        if UIApplication.shared.topMostController() is BannerViewController {
            return
        }

        let delegate = UIApplication.shared.delegate as? OEXAppDelegate
        let delay: Double = delegate?.appOpenedFromExternalLink == true ? DeeplinkDelayTime : 0
        delegate?.appOpenedFromExternalLink = false

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.fetchBanner()
        }
    }

    private func fetchBanner() {
        let request = BannerAPI.unacknowledgedAPI()

        environment.networkManager.taskForRequest(request) { [weak self] result in
            if let link = result.data?.first {
                self?.showBanner(with: link, title: nil, requireAuth: true, showNavbar: false)
            }
        }
    }

    private func showBanner(with link: String, title: String?, requireAuth: Bool, modal: Bool = true, showNavbar: Bool) {
        guard let topController = UIApplication.shared.topMostController(),
              let URL = URL(string: link) else { return }
        environment.router?.showBannerViewController(from: topController, url: URL, title: title, delegate: self, alwaysRequireAuth: requireAuth, modal: modal, showNavbar: showNavbar)
    }

    private func showBrowserViewController(with link: String, title: String? ,requireAuth: Bool) {
        guard let topController = UIApplication.shared.topMostController(),
              let URL = URL(string: link) else { return }
        environment.router?.showBrowserViewController(from: topController, title: title, url: URL)
    }

    //MARK:- BannerViewControllerDelegate

    func navigate(with action: BannerAction, screen: BannerScreen?) {
        switch action {
        case .continueWithoutDismiss:
            if let screen = screen,
               let navigationURL = navigationURL(for: screen) {
                showBanner(with: navigationURL, title: nil, requireAuth: authRequired(for: screen), modal: false, showNavbar: true)
            }
            break
        case .dismiss:
            dismiss(animated: true) { [weak self] in
                if let screen = screen,
                   let navigationURL = self?.navigationURL(for: screen) {
                    self?.showBrowserViewController(with: navigationURL, title: self?.title(for: screen), requireAuth: self?.authRequired(for: screen) ?? false)
                }
            }
            break
        }
    }

    private func navigationURL(for screen: BannerScreen) -> String? {
        switch screen {
        case .privacyPolicy:
            return environment.config.agreementURLsConfig.privacyPolicyURL?.absoluteString
        case .tos:
            return environment.config.agreementURLsConfig.tosURL?.absoluteString
        case .deleteAccount:
            return environment.config.deleteAccountURL
        }
    }

    private func title(for screen: BannerScreen) -> String? {
        switch screen {
        case .deleteAccount:
            return Strings.ProfileOptions.Deleteaccount.webviewTitle
        default:
            return nil
        }
    }

    private func authRequired(for screen: BannerScreen) -> Bool {
        switch screen {
        case .deleteAccount:
            return true
        default:
            return false
        }
    }
}
