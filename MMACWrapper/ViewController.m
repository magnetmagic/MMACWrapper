//
//  ViewController.m
//  MMACWrapper
//
//  Created by matsubaratomoki on 2016/10/02.
//  Copyright © 2016年 magnet-magic. All rights reserved.
//

#import "ViewController.h"
#import "MMACWrapper.h"

static NSString * kSocketURLString = @"ws://www.magnet-magic.com:3002/ac_wrapper_test_channel/";
static NSString * kSocketChannelName = @"AcWrapperTest2Channel";

@interface SubscriptionObject : NSObject
@property MMACSubscription *subscription;
@property NSString *channelName;
@property NSDictionary *params;
@property NSString *displayName;
@property BOOL isConfirmed;
@end

@implementation SubscriptionObject
@end

@interface ViewController ()<MMACWrapperDelegate, UITableViewDelegate,UITableViewDataSource>
@property MMACWrapper *acWrapper;

@property UITableView *tableView;
@property NSMutableArray<NSDictionary*> *list;
@property NSArray <SubscriptionObject*>* subscriptions;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.list = [NSMutableArray array];

    UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)];
    self.navigationItem.leftBarButtonItem = item1;
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(send:)];
    self.navigationItem.rightBarButtonItem = item2;
    
    [self resetSubscriptionObjects];
    
    [self connect:nil];
    
}
- (void)resetSubscriptionObjects{
    SubscriptionObject *param1 = [SubscriptionObject new];
    param1.subscription = nil;
    param1.channelName = kSocketChannelName;
    param1.params = nil;
    param1.displayName = @"NO PARAM TEST";
    param1.isConfirmed= NO;
    SubscriptionObject *param2 = [SubscriptionObject new];
    param2.subscription = nil;
    param2.channelName = kSocketChannelName;
    param2.params = @{@"name": [UIDevice currentDevice].name};
    param2.displayName = @"PARAM TEST";
    param2.isConfirmed= NO;
    self.subscriptions = @[param1,param2];

}
#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.list.count;
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if( !cell )
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    NSDictionary *record = self.list[indexPath.row];
    cell.textLabel.text = record[@"message"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ | %@" , record[@"channel_name"],record[@"by_user"]];
    
    return cell;
}
- (void)addRecord:(NSString*)message fromChannel:(NSString*)channelName byUser:(NSString*)byUser{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.tableView beginUpdates];
        [self.list insertObject:@{@"message":message,@"channel_name":channelName,@"by_user":byUser}
                        atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                              withRowAnimation:(UITableViewRowAnimationTop)];
        [self.tableView endUpdates];
    });
}

#pragma mark - MMACWrapper feature
- (void)connect:(id)sender{
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = !    self.navigationItem.leftBarButtonItem.enabled;
    
    self.acWrapper = [[MMACWrapper alloc]initWithBaseURLString:kSocketURLString
                                                     protocols:nil
                                allowsUntrustedSSLCertificates:NO];
    self.acWrapper.delegate = self;
    [self.acWrapper connect];
}
- (void)send:(id)sender{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"action" message:@"select" preferredStyle:UIAlertControllerStyleActionSheet];

    for( SubscriptionObject *subscriptionObject in  self.subscriptions){
        if( !subscriptionObject.subscription ){
            NSString *title1 = [NSString stringWithFormat:@"subscribe %@" , subscriptionObject.displayName];
            UIAlertAction *action1 = [UIAlertAction actionWithTitle:title1 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                MMACSubscription *subscription = [self.acWrapper subscribe:subscriptionObject.channelName
                                                                withParams:subscriptionObject.params];
                subscriptionObject.subscription = subscription;
            }];
            [alertController addAction:action1];
        }
        
        if( subscriptionObject.subscription && subscriptionObject.isConfirmed ){
            NSString *title2 = [NSString stringWithFormat:@"send message %@" , subscriptionObject.displayName];
            UIAlertAction *action2 = [UIAlertAction actionWithTitle:title2 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.acWrapper sendTo:subscriptionObject.subscription method:@"speak" data:@"hello"];
            }];
            [alertController addAction:action2];
        }
        
        if( subscriptionObject.subscription && subscriptionObject.isConfirmed ){
            NSString *title3 = [NSString stringWithFormat:@"unsubscribled %@" , subscriptionObject.displayName];
            UIAlertAction *action3 = [UIAlertAction actionWithTitle:title3 style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.acWrapper unsubscribe:subscriptionObject.subscription];
                subscriptionObject.isConfirmed = NO;
                subscriptionObject.subscription = nil;
            }];
            [alertController addAction:action3];
        }
    }

    [self presentViewController:alertController animated:YES completion:nil];
    
}
#pragma mark - MMACWrapperDelegate
- (void)acWrapperDidOpen:(MMACWrapper*)acWrapper{
    NSLog(@"Opened");

}
- (void)acWrapperDidReceiveWelcome:(MMACWrapper*)acWrapper {
    NSLog(@"Welcomed");

    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = !self.navigationItem.leftBarButtonItem.enabled;
}

- (void)acWrapper:(MMACWrapper*)acWrapper didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError %@",error);
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = !self.navigationItem.leftBarButtonItem.enabled;
    [self resetSubscriptionObjects];
}
- (void)acWrapperDidclose:(MMACWrapper *)webSocket
         didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    NSLog(@"didCloseWithCode %ld",code);
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = !self.navigationItem.leftBarButtonItem.enabled;
    [self resetSubscriptionObjects];

}
- (void)acWrapper:(MMACWrapper*)acWrapper didReceiveConfirmSubscription:(nonnull MMACSubscription *)subscription{
    NSLog(@"didReceiveConfirmFromChannel %@",subscription.channelName);
    
    for( SubscriptionObject *subscriptionObject in self.subscriptions ){
        if( [subscription isEqualToSubscription:subscriptionObject.subscription]){
            subscriptionObject.isConfirmed = YES;
            [self addRecord:@"confrimed!" fromChannel:subscriptionObject.displayName byUser:@""];
            break;
        }
    }
}
- (void)acWrapper:(MMACWrapper*)acWrapper didReceiveRejectSubscription:(nonnull MMACSubscription *)subscription{
    NSLog(@"didReceiveRejectFromChannel %@",subscription.channelName);
    for( SubscriptionObject *subscriptionObject in self.subscriptions ){
        if( [subscription isEqualToSubscription:subscriptionObject.subscription]){
            subscriptionObject.isConfirmed = NO;
            break;
        }
    }
}

- (void)acWrapper:(MMACWrapper*)acWrapper didReceiveMessage:(NSDictionary*)message fromSubscription:(nonnull MMACSubscription *)subscription{
    NSLog(@"didReceiveMessage %@ %@",message,subscription.channelName);
    for( SubscriptionObject *subscriptionObject in self.subscriptions ){
        if( [subscription isEqualToSubscription:subscriptionObject.subscription]){
            [self addRecord:message[@"message"] fromChannel:subscriptionObject.displayName byUser:message[@"from_user"]?message[@"from_user"]:@""];
            break;
        }
    }
    
}
- (void)acWrapperDidReceivePong:(MMACWrapper *)webSocket{
    NSLog(@"acWrapperDidReceivePong");
    
}
- (void)acWrapperDidReceivePing:(MMACWrapper *)webSocket{
    //
}
@end
