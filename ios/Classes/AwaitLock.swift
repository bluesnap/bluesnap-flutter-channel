//
//  AwaitLock.swift
//  BluesnapSdkFlutter
//
//  Created by MacOS on 7/12/23.
//

import Foundation
import PassKit

@available(iOS 13.0, *)
class AwaitLock {
    
    internal var isLocked: Bool = false
    internal var result: Any?
    internal var timeoutTask: Task<(), Never>?
    
    init() {
        self.isLocked = false;
        self.result = nil;
    }
    
    @available(iOS 13.0.0, *)
    func startLock(timeoutSeconds: Double?) async {
        self.isLocked = true;
        
        //Auto released lock after timeout
        if (timeoutSeconds != nil && timeoutSeconds != 0) {
            
            timeoutTask = Task {
                do {
                    try await Task.sleep(seconds: timeoutSeconds!);
                    self.isLocked = false;
                } catch {}
            }
        }
        
    }
    
    func stopLock(withResult: Any?) {
        self.isLocked = false;
        self.timeoutTask?.cancel();
        
        if(withResult != nil) {
            self.result = withResult!;
        }
    }
    
    @available(iOS 13.0.0, *)
    func awaitLock() async -> Any? {
        do {
            try await Task.sleep(seconds: 1);
            
            if (isLocked) {
                return await self.awaitLock();
            } else {
                return self.result;
            }
            
        } catch {
            return nil;
        }
        
    }
}

@available(iOS 13.0.0, *)
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000);
        try await Task.sleep(nanoseconds: duration);
    }
}
