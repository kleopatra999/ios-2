//
//  ShareFileOrFolder.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareFileOrFolder.h"
#import "AppDelegate.h"
#import "FileDto.h"
#import "OCCommunication.h"
#import "UtilsDtos.h"
#import "ManageFilesDB.h"
#import "constants.h"
#import "AppsActivityProvider.h"
#import "OCErrorMsg.h"
#import "ManageSharesDB.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "UtilsUrls.h"
#import "OCSharedDto.h"
#import "ManageCapabilitiesDB.h"
#import "OCConstants.h"
#import "ManageUsersDB.h"


@implementation ShareFileOrFolder

- (void) initManageErrors {
    //We init the ManageNetworkErrors
    if (!_manageNetworkErrors) {
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
}

- (void) showShareActionSheetForFile:(FileDto *)file {
    
    [self initManageErrors];
    
    if ((APP_DELEGATE.activeUser.hasShareApiSupport == serverFunctionalitySupported || APP_DELEGATE.activeUser.hasShareApiSupport == serverFunctionalityNotChecked)) {
        _file = file;
        
        //We check if the file is shared
        if (_file.sharedFileSource > 0) {
            
            //The file is shared so we show the options to share or unshare link
            if (self.shareActionSheet) {
                self.shareActionSheet = nil;
            }
            
            self.shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:NSLocalizedString(@"unshare_link", nil) otherButtonTitles:NSLocalizedString(@"share_link_long_press", nil), nil];
            
            if (!IS_IPHONE){
                [self.shareActionSheet showInView:_viewToShow];
            } else {
                
                [self.shareActionSheet showInView:[_viewToShow window]];
            }
        } else {
            //The file is not shared so we launch the sharing inmediatly
            [self clickOnShareLinkFromFileDto:YES];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"share_not_available_on_this_server", nil)
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self clickOnUnShare];
            
            break;
        case 1:
            [self clickOnShareLinkFromFileDto:YES];
            
            break;
        case 2:
            DLog(@"Cancel");
            break;
    }
}


#pragma mark - Share Requests (create, update, unshare)

- (void) doRequestCreateShareLinkOfFile:(FileDto *)file withPassword:(NSString *)password expirationTime:(NSString*)expirationTime publicUpload:(NSString *)publicUpload andLinkName:(NSString *)linkName {
    
    [self initManageErrors];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    
    NSString *filePath = [UtilsUrls getFilePathOnDBwithRootSlashAndWithFileName:file.fileName ByFilePathOnFileDto:file.filePath andUser:app.activeUser];

    
    [[AppDelegate sharedOCCommunication] shareFileOrFolderByServerPath:[UtilsUrls getFullRemoteServerPath:app.activeUser] withFileOrFolderPath:filePath password:password expirationTime:expirationTime publicUpload:publicUpload linkName:linkName onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *token, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
        } else {
            [self.delegate sharelinkOptionsUpdated];
        }

    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
            
        } else {
            
            DLog(@"error.code: %ld", (long)error.code);
            DLog(@"server error: %ld", (long)response.statusCode);
            
            if (error.code == kOCErrorServerForbidden && [ShareUtils isPasswordEnforcedCapabilityEnabled]) {
                
                //Share whith password maybe enabled, ask for password and try to do the request again with it
                // [self showAlertEnterPassword]; //TODO: ask password if needed
                
            } else {
                [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
            }
            
            if (error.code != kOCErrorServerForbidden) {
                
                //                if([self.delegate respondsToSelector:@selector(finishShareWithStatus:andWithOptions:)]) {
                //                    [self.delegate finishShareWithStatus:false andWithOptions:nil];
                //                }
            }
        }

    }];
     
    
}


- (void) doRequestUpdateShareLink:(OCSharedDto *)ocShare withPassword:(NSString*)password expirationTime:(NSString*)expirationTime publicUpload:(NSString *)publicUpload andLinkName:(NSString *)linkName {
    
    [self initManageErrors];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];

    password = [ShareUtils getPasswordEncodingWithPassword:password];
    
    [[AppDelegate sharedOCCommunication] updateShare:ocShare.idRemoteShared ofServerPath:[UtilsUrls getFullRemoteServerPath:app.activeUser] withPasswordProtect:password andExpirationTime:expirationTime andPublicUpload:publicUpload andLinkName:linkName onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
        } else {
            [self.delegate sharelinkOptionsUpdated]; //TODO:return ocsharedDto instead of responsese data and not call sharelinkoptionsupdated
        }
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
        } else {
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }

    }];
}


///-----------------------------------
/// @name Unshare the file
///-----------------------------------

/**
 * This method unshares the file/folder
 *
 * @param OCSharedDto -> The shared file/folder
 */
- (void)unshareTheFileByIdRemoteShared:(NSInteger)idRemoteShared {
    
    [self initManageErrors];

    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [self initLoading];
    
    //In iPad set the global variable
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = YES;
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    [[AppDelegate sharedOCCommunication] unShareFileOrFolderByServer:[UtilsUrls getFullRemoteServerPath:app.activeUser] andIdRemoteShared:idRemoteShared onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        [self endLoading];
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
                
//                if([self.delegate respondsToSelector:@selector(finishUnShareWithStatus:)]) {
//                    [self.delegate finishUnShareWithStatus:false];
//                }
            }
        }
        
        if (!isSamlCredentialsError) {
            [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
            
//            if([self.delegate respondsToSelector:@selector(finishUnShareWithStatus:)]) {
//                [self.delegate finishUnShareWithStatus:true];
//            }

        }

        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
        [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
        [self endLoading];
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
                
            }
        }
        if (!isSamlCredentialsError) {
           
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }
        
        if([self.delegate respondsToSelector:@selector(finishUnShareWithStatus:)]) {
            [self.delegate finishUnShareWithStatus:false];
        }

        
    }];
}

- (void) checkSharedStatusOfFile:(FileDto *) file {
    
    [self initManageErrors];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [self initLoading];
    
    //In iPad set the global variable
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = YES;
    }

    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:APP_DELEGATE.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:APP_DELEGATE.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:APP_DELEGATE.activeUser.username andPassword:APP_DELEGATE.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    FileDto *parentFolder = [ManageFilesDB getFileDtoByIdFile:file.fileId];
    
    NSString *path = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:parentFolder.filePath andUser:APP_DELEGATE.activeUser];
    path = [path stringByAppendingString:parentFolder.fileName];
    path = [path stringByRemovingPercentEncoding];
    
    [[AppDelegate sharedOCCommunication] readSharedByServer:APP_DELEGATE.activeUser.url andPath:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self endLoading];
                [self errorLogin];
                
//                if([self.delegate respondsToSelector:@selector(finishCheckSharedStatusOfFile:)]) {
//                    [self.delegate finishCheckSharedStatusOfFile:false];
//                }
            }
        }
        
        if (!isSamlCredentialsError) {
            
            NSArray *itemsToDelete = [ManageSharesDB getSharesByFolderPath:[NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:parentFolder.filePath andUser:APP_DELEGATE.activeUser], parentFolder.fileName]];
            
            //1. We remove the removed shared from the Files table of the current folder
            [ManageFilesDB setUnShareFilesOfFolder:parentFolder];
            //2. Delete all shared to not repeat them
            [ManageSharesDB deleteLSharedByList:itemsToDelete];
            //3. Delete all the items that we want to insert to not insert them twice
            [ManageSharesDB deleteLSharedByList:listOfShared];
            //4. We add the new shared on the share list
            [ManageSharesDB insertSharedList:listOfShared];
            //5. Update the files with shared info of this folder
            [ManageFilesDB updateFilesAndSetSharedOfUser:APP_DELEGATE.activeUser.idUser];
            
            [self endLoading];
            
            if([self.delegate respondsToSelector:@selector(finishCheckSharedStatusOfFile:)]) {
                [self.delegate finishCheckSharedStatusOfFile:true];
            }
            
        }

        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
        [self endLoading];
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        
        if (!isSamlCredentialsError) {
            
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }
        
        if([self.delegate respondsToSelector:@selector(finishCheckSharedStatusOfFile:)]) {
            [self.delegate finishCheckSharedStatusOfFile:false];
        }
    }];
    
    
}



///-----------------------------------
/// @name clickOnUnShare
///-----------------------------------

/**
 * Method to obtain the share the file or folder
 *
 */
- (void) clickOnUnShare {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSArray *sharesOfFile = [ManageSharesDB getSharesBySharedFileSource:_file.sharedFileSource forUser:app.activeUser.idUser];
    OCSharedDto *sharedByLink;
    
    for (OCSharedDto *current in sharesOfFile) {
        if (current.shareType == shareTypeLink) {
            sharedByLink = current;
        }
    }
    
    [self unshareTheFileByIdRemoteShared:sharedByLink.idRemoteShared];
}


#pragma mark - Utils

- (void) refreshSharedItemInDataBase:(OCSharedDto *) item {
    
    NSArray* items = [NSArray arrayWithObject:item];
    
    [ManageSharesDB deleteLSharedByList:items];
    
    [ManageSharesDB insertSharedList:items];
    
    [ManageFilesDB updateFilesAndSetSharedOfUser:APP_DELEGATE.activeUser.idUser];
}


#pragma mark - Loading Methods

///-----------------------------------
/// @name endLoading
///-----------------------------------


- (void) initLoading{
    
    if([self.delegate respondsToSelector:@selector(initLoading)]) {
        [self.delegate initLoading];
    }
}

/**
 * Method to hide the Loading view
 *
 */
- (void) endLoading {
    
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = NO;
    
    if([self.delegate respondsToSelector:@selector(endLoading)]) {
        [self.delegate endLoading];
    }
}

- (void) errorLogin {
    
    if([self.delegate respondsToSelector:@selector(errorLogin)]) {
        [self.delegate errorLogin];
    }
    
}


/*
 * Show the standar message of the error connection.
 */
- (void)showError:(NSString *) message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    });
}


@end
