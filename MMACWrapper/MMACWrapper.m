//
//  MMACWrapper.m
//  MMACWrapper
//
//  Created by matsubaratomoki on 2016/10/02.
//  Copyright © 2016年 magnet-magic. All rights reserved.
//

#import "MMACWrapper.h"

@interface NSDictionary(MMToString)
-(NSString*)serializeToJSONString;
@end

@interface NSString(MMToJSON)
-(NSDictionary*)toJSON;
@end

@interface MMACSubscription()
@property NSString *channelName;
@property NSDictionary<NSString*,id> *params;
+ (instancetype)subscriptionWithIndentifierString:(NSString*)identifier;
- (instancetype)initWithChannelName:(NSString*)channelName
                             params:(nullable NSDictionary<NSString*,id>* )  params;
+ (instancetype)subscriptionForChannelName:(NSString*)channelName
                                    params:(nullable NSDictionary<NSString*,id>* )  params;
-(NSString*)identifyString;
@end

@interface MMACWrapper()<SRWebSocketDelegate>
@property SRWebSocket *webSocket;
@property NSString *baseURLString;
@property NSArray *protocols;
@property BOOL allowsUntrustedSSLCertificates;
@end

@implementation MMACWrapper

- (instancetype)initWithBaseURLString:(NSString*)urlString
                            protocols:(NSArray*)protocols
       allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates{
    self = [super init];
    if( self ){
        self.baseURLString = urlString;
        self.protocols = protocols;
        self.allowsUntrustedSSLCertificates = allowsUntrustedSSLCertificates;
    }
    return self;
}

- (void)connect{
    [self reconnect];
}
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    if( [self.delegate respondsToSelector:@selector(acWrapperDidOpen:)] ){
        [self.delegate acWrapperDidOpen:self];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@"WebSocket closed error");
    if( [self.delegate respondsToSelector:@selector(acWrapper:didFailWithError:)] ){
        [self.delegate acWrapper:self didFailWithError:error];
    }
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    if( [self.delegate respondsToSelector:@selector(acWrapperDidclose:didCloseWithCode:reason:wasClean:)] ){
        [self.delegate acWrapperDidclose:self didCloseWithCode:code reason:reason wasClean:wasClean];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSDictionary *dic = nil;
    NSData *data = message;
    NSError *error = nil;
    if( [message isKindOfClass:[NSString class]] ){
        data = [message dataUsingEncoding:NSUTF8StringEncoding];
    }
    dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if( [dic[@"type"] isEqualToString:@"ping"]){
        if( [self.delegate respondsToSelector:@selector(acWrapperDidReceivePing:)] ){
            [self.delegate acWrapperDidReceivePing:self];
        }
    }
    else if( [dic[@"type"] isEqualToString:@"welcome"]){
        if( [self.delegate respondsToSelector:@selector(acWrapperDidReceiveWelcome:)] ){
            [self.delegate acWrapperDidReceiveWelcome:self ];
        }
        return;
    }
    else if( [dic[@"type"] isEqualToString:@"confirm_subscription"]){
        if( [self.delegate respondsToSelector:@selector(acWrapper:didReceiveConfirmSubscription:)] ){
            [self.delegate acWrapper:self didReceiveConfirmSubscription:[MMACSubscription subscriptionWithIndentifierString:dic[@"identifier"]]];
        }
        // confirm
    }
    else if( [dic[@"type"] isEqualToString:@"reject_subscription"]){
        // reject
        if( [self.delegate respondsToSelector:@selector(acWrapper:didReceiveRejectSubscription:)] ){
            [self.delegate acWrapper:self didReceiveRejectSubscription:[MMACSubscription subscriptionWithIndentifierString:dic[@"identifier"]]];
        }
    }
    else if( dic[@"message"] )
    {
        NSLog(@"Received \"%@\"", message);
        id object = dic[@"message"];
        if( [object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSArray class]]){
            if( [self.delegate respondsToSelector:@selector(acWrapper:didReceiveMessage:fromSubscription:)] ){
                [self.delegate acWrapper:self didReceiveMessage:object fromSubscription:[MMACSubscription subscriptionWithIndentifierString:dic[@"identifier"]]];
            }
        }
        else if( [object isKindOfClass:[NSString class]] ){
            NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:[(NSString*)object dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            if( messageDictionary ){
                if( [self.delegate respondsToSelector:@selector(acWrapper:didReceiveMessage:fromSubscription:)] ){
                    [self.delegate acWrapper:self didReceiveMessage:messageDictionary fromSubscription:[MMACSubscription subscriptionWithIndentifierString:dic[@"identifier"]]];
                }
            }
            if( [self.delegate respondsToSelector:@selector(acWrapper:didReceiveMessage:fromSubscription:)] ){
                [self.delegate acWrapper:self didReceiveMessage:object fromSubscription:[MMACSubscription subscriptionWithIndentifierString:dic[@"identifier"]]];
            }
        }
        else{
//            if( [self.delegate respondsToSelector:@selector(acWrapper:didReceiveMessage:fromChannel:)] ){
//                [self.delegate acWrapper:self didReceiveMessage:nil fromChannel:[self identifier:dic]];
//            }
        }

    }else{
        // unknown type
        
    }
}
-(NSString*)identifier:(NSDictionary*)dic{
    NSString *channelIdentifierString = dic[@"identifier"];

    NSDictionary * channelIdentifier = [channelIdentifierString toJSON];

    return channelIdentifier[@"channel"];
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
//    NSLog(@"WebSocket received pong");
}
- (void)reconnect
{
    self.webSocket.delegate = nil;
    [self.webSocket close];
    
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:self.baseURLString]
                                            protocols:self.protocols
                       allowsUntrustedSSLCertificates:self.allowsUntrustedSSLCertificates];
    self.webSocket.delegate = self;
    
    [self.webSocket open];
}
- (void)disconnect{
    self.webSocket.delegate = nil;
    self.webSocket = nil;
}

- (MMACSubscription*)subscribe:(NSString*)channelName withParams:(NSDictionary*)params{
    
    MMACSubscription *subscription = [MMACSubscription subscriptionForChannelName:channelName
                                                                            params:params];

    return [self subscribe:subscription];
}

- (MMACSubscription*)subscribe:(MMACSubscription*)subscription{
    
    
//    identify = additionalKey && additionalParam ? @{@"channel":channelName,additionalKey:additionalParam}:@{@"channel":channelName};
//    identify = @{@"channel":channelName};
    
    NSDictionary *param = @{@"command":@"subscribe",@"identifier":[subscription identifyString]};
    
    NSString *message = [param serializeToJSONString];
    [self.webSocket send:message];
    
    return subscription;    
}
- (void)unsubscribe:(MMACSubscription*)subscription{
    
    NSDictionary *param = @{@"command":@"unsubscribe",@"identifier":[subscription identifyString]};
    
    NSString *message = [param serializeToJSONString];
    [self.webSocket send:message];
    
}
-(void)sendTo:(MMACSubscription*)subscription method:(NSString*)method data:(id)data{

    NSDictionary *payload = @{@"message":data,@"action":method};
    NSString *payloadString = [payload serializeToJSONString];

    NSDictionary *param = @{@"command" : @"message" , @"identifier" : [subscription identifyString] , @"data" : payloadString };
    NSString *paramString = [param serializeToJSONString];

    NSLog(@"paramString = %@",paramString);

    [self.webSocket send:paramString];
    
}
@end



@implementation NSDictionary(MMToString)
-(NSString*)serializeToJSONString{
    NSData *workData  = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil] ;
    NSString *workString = [[NSString alloc]initWithData:workData encoding:NSUTF8StringEncoding];
    return workString;
}
@end

@implementation NSString(MMToJSON)
-(NSDictionary*)toJSON{
    NSError *error = nil;
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if( error )return nil;

    return dictionary;
}
@end


@implementation MMACSubscription
+ (instancetype)subscriptionForChannelName:(NSString*)channelName
                                    params:(nullable NSDictionary<NSString*,id>* )  params{
    MMACSubscription *subscription = [[MMACSubscription alloc]initWithChannelName:channelName
                                                                           params:params];
    return subscription;
}

- (instancetype)initWithChannelName:(NSString*)channelName
                             params:(nullable NSDictionary<NSString*,id>* )  params{
    self = [super init];
    if( self ){
        self.channelName = channelName;
        if( params.allKeys )
            self.params = params;
        else
            self.params = nil;
    }
    return self;
}
-(NSString*)identifyString{
    NSMutableDictionary *work = [NSMutableDictionary dictionary];
    work[@"channel"] = self.channelName;
    for( NSString *key in self.params.keyEnumerator ){
        work[key] = self.params[key];
    }
    
    NSString *identifyString = [work serializeToJSONString];
    
    return identifyString;
}
+ (instancetype)subscriptionWithIndentifierString:(NSString*)identifier{
    
    NSDictionary * channelIdentifier = [identifier toJSON];
    NSString *channelName = nil;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for( NSString *key in channelIdentifier.keyEnumerator ){
        if( [key isEqualToString:@"channel"]){
            channelName = channelIdentifier[key];
        }else{
            params[key] = channelIdentifier[key];
        }
    }
    MMACSubscription *subscription = [MMACSubscription subscriptionForChannelName:channelName
                                                                           params:params.allKeys.count?params:nil];
    
    return subscription;
}
- (BOOL)isEqualToSubscription:(MMACSubscription*)other{
    if( ![self.channelName isEqualToString:other.channelName]){
        return NO;
    }
    if( self.params == nil && other.params == nil ){
        return YES;
    }
    if( self.params == nil || other.params == nil ){
        return NO;
    }
    return [self.params isEqualToDictionary:other.params];
}
@end
