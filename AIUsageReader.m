#import "AIUsageReader.h"
#import <sqlite3.h>

@implementation AIUsageReader

+ (instancetype)sharedReader {
    static AIUsageReader *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AIUsageReader alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dailyLimit = 200;
    }
    return self;
}

- (NSString *)stateDatabasePath {
    NSString *home = NSHomeDirectory();
    return [home stringByAppendingPathComponent:@"Library/Application Support/Antigravity IDE/User/globalStorage/state.vscdb"];
}

- (NSString *)antigravityStatePath {
    NSString *home = NSHomeDirectory();
    return [home stringByAppendingPathComponent:@".gemini/antigravity/antigravity_state.pbtxt"];
}

- (NSString *)quotaScriptPath {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"get_quota" ofType:@"py"];
    if (bundlePath && [[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
        return bundlePath;
    }
    return @"/Users/lucasmachado/Documents/touchbar/get_quota.py";
}

- (AIUsageSnapshot *)fetchCurrentSnapshot {
    AIUsageSnapshot *snapshot = [[AIUsageSnapshot alloc] init];
    
    // 1. Informações de Usuário e Modelo
    [self populateFromVscDb:snapshot];
    [self populateFromPbtxt:snapshot];
    
    // 2. Buscar COTA REAL diretamente do Language Server do Antigravity IDE
    [self fetchLiveQuotaFromLanguageServer:snapshot];
    
    snapshot.lastUpdated = [NSDate date];
    return snapshot;
}

- (void)fetchLiveQuotaFromLanguageServer:(AIUsageSnapshot *)snapshot {
    NSString *script = [self quotaScriptPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:script]) {
        return;
    }
    
    @try {
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/python3";
        task.arguments = @[script];
        
        NSPipe *pipe = [NSPipe pipe];
        task.standardOutput = pipe;
        
        [task launch];
        [task waitUntilExit];
        
        if (task.terminationStatus == 0) {
            NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
            if (data && data.length > 0) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (json) {
                    snapshot.geminiFiveHour = [json[@"geminiFiveHour"] doubleValue];
                    snapshot.geminiWeekly = [json[@"geminiWeekly"] doubleValue];
                    snapshot.geminiFiveHourDesc = json[@"geminiFiveHourDesc"] ?: @"";
                    snapshot.geminiWeeklyDesc = json[@"geminiWeeklyDesc"] ?: @"";
                    snapshot.claudeFiveHour = [json[@"claudeFiveHour"] doubleValue];
                    snapshot.claudeWeekly = [json[@"claudeWeekly"] doubleValue];
                    
                    // A porcentagem primária exibida no Touch Bar é a cota ativa de 5 horas (a mais próxima do limite)
                    snapshot.remainingPercent = [json[@"primaryPercent"] doubleValue];
                }
            }
        }
    } @catch (NSException *e) {
        NSLog(@"[AITouchBar] Erro ao executar get_quota.py: %@", e.reason);
    }
}

- (void)populateFromVscDb:(AIUsageSnapshot *)snapshot {
    NSString *dbPath = [self stateDatabasePath];
    sqlite3 *db = NULL;
    int flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI;
    if (sqlite3_open_v2([dbPath UTF8String], &db, flags, NULL) != SQLITE_OK) {
        return;
    }
    sqlite3_busy_timeout(db, 1000);
    
    sqlite3_stmt *stmt = NULL;
    const char *query = "SELECT value FROM ItemTable WHERE key = 'antigravityUnifiedStateSync.userStatus'";
    if (sqlite3_prepare_v2(db, query, -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            const char *val = (const char *)sqlite3_column_text(stmt, 0);
            if (val) {
                NSString *b64 = [NSString stringWithUTF8String:val];
                NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                if (data) {
                    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                    if (decoded) {
                        // Email
                        NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})" options:0 error:nil];
                        NSTextCheckingResult *match = [emailRegex firstMatchInString:decoded options:0 range:NSMakeRange(0, decoded.length)];
                        if (match) {
                            snapshot.userEmail = [decoded substringWithRange:match.range];
                        }
                        
                        // Plano (Google AI Pro, etc.)
                        if ([decoded containsString:@"Google AI Pro"] || [decoded containsString:@"pro-tier"]) {
                            snapshot.planName = @"Google AI Pro";
                        } else if ([decoded containsString:@"Antigravity Starter Quota"]) {
                            snapshot.planName = @"Starter Quota";
                        }
                        
                        if ([decoded containsString:@"Marina"]) {
                            snapshot.userAccount = @"Marina Nobre";
                        }
                    }
                }
            }
        }
        sqlite3_finalize(stmt);
    }
    sqlite3_close(db);
}

- (void)populateFromPbtxt:(AIUsageSnapshot *)snapshot {
    NSString *pbtxtPath = [self antigravityStatePath];
    NSError *err = nil;
    NSString *content = [NSString stringWithContentsOfFile:pbtxtPath encoding:NSUTF8StringEncoding error:&err];
    if (content) {
        if ([content containsString:@"MODEL_PLACEHOLDER_M20"]) {
            snapshot.modelName = @"Gemini 3.8 Flash (Medium)";
        } else if ([content containsString:@"MODEL_PLACEHOLDER_M19"]) {
            snapshot.modelName = @"Gemini 3.8 Flash (High)";
        } else if ([content containsString:@"MODEL_PLACEHOLDER_M21"]) {
            snapshot.modelName = @"Gemini 3.8 Flash (Low)";
        } else if ([content containsString:@"Claude Sonnet"]) {
            snapshot.modelName = @"Claude Sonnet 4.6";
        } else if ([content containsString:@"Claude Opus"]) {
            snapshot.modelName = @"Claude Opus 4.6";
        }
    }
}

@end
