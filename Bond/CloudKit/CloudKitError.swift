// CloudKitError.swift
// Bond

import CloudKit
import Foundation

enum CloudKitError: LocalizedError {
    case iCloudNotAvailable
    case bondNotFound
    case bondFull
    case alreadyMember
    case codeAlreadyExists
    case assetEncodingFailed
    case assetDownloadFailed
    case networkUnavailable
    case rateLimited(retryAfter: Double)
    case serverError(CKError)
    case unknown(Error)

    // MARK: - Mensagens para o usuário

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .bondNotFound:
            return "Bond not found. Check the code and try again."
        case .bondFull:
            return "This Bond is full and can't accept new members."
        case .alreadyMember:
            return "You're already a member of this Bond."
        case .codeAlreadyExists:
            return "Something went wrong generating the invite code. Please try again."
        case .assetEncodingFailed:
            return "Failed to process the image. Please try again."
        case .assetDownloadFailed:
            return "Failed to download media. Check your connection."
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let ck):
            return "Server error: \(ck.localizedDescription)"
        case .unknown(let e):
            return e.localizedDescription
        }
    }

    // MARK: - Mapeamento de CKError

    static func from(_ error: Error) -> CloudKitError {
        guard let ck = error as? CKError else { return .unknown(error) }
        switch ck.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated:
            return .iCloudNotAvailable
        case .requestRateLimited:
            let retry = ck.userInfo[CKErrorRetryAfterKey] as? Double ?? 5.0
            return .rateLimited(retryAfter: retry)
        default:
            return .serverError(ck)
        }
    }
}
