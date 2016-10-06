//
//  MMACWrapper.h
//  MMACWrapper
//
//  Created by matsubaratomoki on 2016/10/02.
//  Copyright © 2016年 magnet-magic. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "SocketRocket.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MMACWrapperDelegate;
@class MMACSubscription;

/**
 MMACWrapper
 A wrapper class of SocketRocket to connect Ruby on Rails ActionCable service.
 */
@interface MMACWrapper : NSObject

@property (readonly) SRWebSocket *webSocket;
@property (assign) id<MMACWrapperDelegate> delegate;

/** initialize instance
  *
  * @param urlString URL String like (@"ws://XXXX.YYY:nnn/ZZZ/")
  * @param protocols see SRWebSocket
 * @param allowsUntrustedSSLCertificates see SRWebSocket
  * @return instance
  */
- (instancetype)initWithBaseURLString:(NSString*)urlString
                            protocols:(nullable NSArray*)protocols
       allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (instancetype) init __attribute__((unavailable("use initWithBaseURLString::")));
+ (instancetype) new __attribute__((unavailable("use alloc initWithBaseURLString::")));

/** connect
 * call back acWrapperDidOpen: AND acWrapperDidReceiveWelcome: if connect successfully
  */
- (void)connect;

/** subscribe
 * call back acWrapper:didReceiveConfirmSubscription OR acWrapper:didReceiveRejectSubscription
 *
  * @param channelName channel name (ApplicationCable::Channel class name)
  * @param params Arguments given as "params" to ApplicationCable::Channel#subscribed method
  * @return MMACSubscription subscription object
  */
- (MMACSubscription*)subscribe:(NSString*)channelName withParams:(NSDictionary*)params;

/** unsubscribe
  *
  * @param subscription confirmed subscription object
  */
- (void)unsubscribe:(MMACSubscription*)subscription;

/** disconnect
  * disconnect from ActionCable
  */
- (void)disconnect;

/** sendTo
  * send message to subscription
 *
  * @param subscription confirmed subscription object
  * @param method method name in ApplicationCable::Channel subclass
 * @param data parameter
  */
- (void)sendTo:(MMACSubscription*)subscription method:(NSString*)method data:(id)data;

@end


/**
 MMACWrapperDelegate
 MMACWrapper class's delegate protocol
 */
@protocol MMACWrapperDelegate <NSObject>

@optional

/** call when connection opened
  *
  * @param acWrapper MMACWrapper class
  */
- (void)acWrapperDidOpen:(MMACWrapper*)acWrapper ;


/** call when received "welcome" type message after sending subscribeChannel:.
  *
  * @param acWrapper MMACWrapper class
  */
- (void)acWrapperDidReceiveWelcome:(MMACWrapper*)acWrapper ;

/** call when received "confirm_subscription" type message after sending subscribeChannel:.
  *
  * @param acWrapper MMACWrapper class
  * @param subscription Subscription object to ActionCable
  */
- (void)acWrapper:(MMACWrapper*)acWrapper didReceiveConfirmSubscription:(MMACSubscription*)subscription;


/** call when received "reject_subscription" type message after sending subscribeChannel:
  *
  * @param acWrapper MMACWrapper class
  * @param subscription Subscription object to ActionCable
  */
- (void)acWrapper:(MMACWrapper*)acWrapper didReceiveRejectSubscription:(MMACSubscription*)subscription;


/** call when received message.
  *
  * @param acWrapper MMACWrapper class
  * @param message  message
  * @param subscription Subscription object to ActionCable
  */
- (void)acWrapper:(MMACWrapper*)acWrapper didReceiveMessage:(NSDictionary*)message fromSubscription:(MMACSubscription*)subscription;

/** call when received some error.
  *
  * @param acWrapper MMACWrapper class
  * @param error  error  see SRWebSocket.h
  */
- (void)acWrapper:(MMACWrapper*)acWrapper didFailWithError:(NSError *)error;
/** call when connection is closed for some reason.
  *
  * @param acWrapper MMACWrapper class
  * @param code  error  see SRWebSocket.h
  * @param reason  see SRWebSocket.h
  * @param wasClean  see SRWebSocket.h
  */
- (void)acWrapperDidclose:(MMACWrapper *)acWrapper didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

/** call when received "ping" type message
  *
  * @param acWrapper MMACWrapper class
  */
- (void)acWrapperDidReceivePing:(MMACWrapper *)acWrapper;

@end


/**
 MMACSubscription
 Subscription object for ActionCable.
 */
@interface MMACSubscription : NSObject
@property (readonly) NSString *channelName;
@property (readonly) NSDictionary<NSString*,id> *params;
- (instancetype) init __attribute__((unavailable("do not init")));
+ (instancetype) new __attribute__((unavailable("do not new")));
- (BOOL)isEqualToSubscription:(MMACSubscription*)other;
@end

NS_ASSUME_NONNULL_END
