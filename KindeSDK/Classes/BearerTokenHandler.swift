import AppAuth

public class BearerTokenHandler {
    public static let notAuthenticatedCode = 401
    
    /// Ensure a valid Bearer token is present.
    ///
    /// Token refresh is performed using the `AppAuth` convenience function, `performWithFreshTokens`
    /// This will refresh an expired access token if required, and if the refresh token is expired,
    /// a fresh login will need to be performed.
    ///
    /// A failure with error `notAuthenticatedCode` likely indicates a fresh login is required.
    static func setBearerToken(completionHandler: @escaping (Error?) -> Void) {
        Auth.performWithFreshTokens { tokens in
            switch tokens {
            case let .failure(error):
                print("Failed to get auth token: \(error.localizedDescription)")
                completionHandler(error)
            case let .success(tokens):
                OpenAPIClientAPI.customHeaders["Authorization"] = "Bearer \(tokens.accessToken)"
                completionHandler(nil)
            }
        }
    }
    
    /// Transform an error arising from `setBearerToken` into an `ErrorResponse`
    ///
    /// Authentication errors are given response code `notAuthenticatedCode` and will likely require a fresh login. All other
    /// errors are given a nominal value.
    static func handleSetBearerTokenError<T>(error: Error, completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) {
        switch error {
        case AuthError.notAuthenticated:
            // Indicate a bearer token could not be set due to an authentication error; likely due to an expired refresh token
            completion(Result.failure(ErrorResponse.error(BearerTokenHandler.notAuthenticatedCode, nil, nil, error)))
        default:
            completion(Result.failure(ErrorResponse.error(-1, nil, nil, error)))
        }
    }
}
