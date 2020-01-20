//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

extension MainViewController {
    /// The simplest of inbox.
    /// Inbox looks best when embedded in a navigation controller. It has a `Done` button.
    @IBAction private func onSimpleInboxTapped() {
        // <ignore -- data loading>
        loadDataset(number: 1)
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        present(viewController, animated: true)
    }
}
