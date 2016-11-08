//
//  Created by Guy Kahlon.
//

import Foundation
import RxSwift
import Starscream

import Foundation
import RxSwift
import Starscream

public enum WebSocketEvent {
  case connected
  case disconnected(NSError?)
  case message(String)
  case data(Foundation.Data)
  case pong
}

open class RxWebSocket: WebSocket {
  
  fileprivate let subject = PublishSubject<WebSocketEvent>()
  fileprivate var forwardDelegate: WebSocketDelegate?
  fileprivate var forwardPongDelegate: WebSocketPongDelegate?
  
  open override weak var delegate: WebSocketDelegate? {
    didSet {
      if delegate === self {
        return
      }
      forwardDelegate = delegate
      delegate = self
    }
  }
  
  open override weak var pongDelegate: WebSocketPongDelegate? {
    didSet {
      if pongDelegate === self {
        return
      }
      forwardPongDelegate = pongDelegate
      pongDelegate = self
    }
  }
  
  open fileprivate(set) lazy var rx_response: Observable<WebSocketEvent> = {
    return self.subject
  }()
  
  open fileprivate(set) lazy var rx_text: Observable<String> = {
    return self.subject.filter { response in
      switch response {
      case .Message(_):
        return true
      default:
        return false
      }
      }.map { response in
        switch response {
        case .Message(let message):
          return message
        default:
          return String()
        }
    }
  }()
  
  open override func connect() {
    super.connect()
    delegate = self
    pongDelegate = self
  }
}

extension RxWebSocket: WebSocketPongDelegate {
  public func websocketDidReceivePong(_ socket: WebSocket) {
    subject.on(.Next(WebSocketEvent.Pong))
  }
}

extension RxWebSocket: WebSocketDelegate {
  
  public func websocketDidConnect(_ socket: WebSocket) {
    subject.on(.Next(WebSocketEvent.Connected))
    forwardDelegate?.websocketDidConnect(socket)
  }
  
  public func websocketDidDisconnect(_ socket: WebSocket, error: NSError?) {
    subject.on(.Next(WebSocketEvent.Disconnected(error)))
    forwardDelegate?.websocketDidDisconnect(socket, error: error)
    socket.delegate = nil
  }
  
  public func websocketDidReceiveMessage(_ socket: WebSocket, text: String) {
    subject.on(.Next(WebSocketEvent.Message(text)))
    forwardDelegate?.websocketDidReceiveMessage(socket, text: text)
  }
  
  public func websocketDidReceiveData(_ socket: WebSocket, data: Data) {
    subject.on(.Next(WebSocketEvent.Data(data)))
    forwardDelegate?.websocketDidReceiveData(socket, data: data)
  }
}
