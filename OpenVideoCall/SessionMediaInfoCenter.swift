//
//  SessionMediaInfoCenter.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 4/11/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Cocoa

class SessionMediaInfoCenter {
    class func updateInfoViewOfSessions(sessions: [VideoSession], fullSession: VideoSession?, isShowingWhiteboard: Bool) {
        guard sessions.count > 0 else {
            return
        }
        
        var showSessions = [VideoSession]()
        var hideSessions = [VideoSession]()
        
        if !isShowingWhiteboard {
            switch sessions.count {
            case 1:
                showSessions = sessions
            case 2:
                showSessions.append(sessions.last!)
                hideSessions.append(sessions.first!)
            default:
                if let fullSession = fullSession {
                    showSessions.append(fullSession)
                    
                    for session in sessions {
                        if session != fullSession {
                            hideSessions.append(session)
                        }
                    }
                } else {
                    showSessions = sessions
                }
            }
        } else {
            hideSessions = sessions
        }
        
        for session in showSessions {
            session.shouldShowInfos = true
        }
        for session in hideSessions {
            session.shouldShowInfos = false
        }
    }
}
