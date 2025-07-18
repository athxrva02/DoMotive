//
//  CloudKitCheck.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// iCloudStatusChecker.swift
import CloudKit

func checkiCloudStatus(completion: @escaping (Bool) -> Void) {
    CKContainer.default().accountStatus { status, error in
        DispatchQueue.main.async {
            completion(status == .available)
        }
    }
}

