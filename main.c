#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include "jsmn.h"

#define magic "i3-ipc"
#define headerLength (strlen(magic)+sizeof(int32_t)+sizeof(int32_t))

int s;
int jumpCount = 0;

void
panic(char *s) {
    fputs(s, stderr);
    exit(-1);
}

ssize_t
sendInt(int32_t i) {
    return write(s, &i, 4);
}

void
sendHeader() {
    write(s, "i3-ipc", 6);
}

int32_t
getResponseLen() {
    char header[headerLength];
    ssize_t rn = read(s, header, headerLength);
    if(strncmp(magic, header, strlen(magic)) || rn != headerLength)
        return -1;
    int32_t n;
    memcpy(&n, &header[strlen(magic)], 4);
    return n;
}

void
printTok(char *j, jsmntok_t t) {
    printf("parent: %d  type: %d  start: %d  end: %d  size: %d\n"
        , t.parent
        , t.type
        , t.start
        , t.end
        , t.size);
}

void
printToks(char *j, jsmntok_t *ts, int tlen) {
    int i;
    for(i=0; i<tlen; i++) {
        printf("%d  ", i);
        printTok(j, ts[i]);
    }
}

typedef struct {
    char *s;
    int len;
} strn;

typedef enum {
    WS_CurrentHasWindows = 1,
    WS_WantedHasWindows = 1 << 1,
    WS_WantedVisible = 1 << 2
} wantedState;

typedef struct {
    wantedState wantedState;
    strn wantedOutput;
    strn currentOutput;
    strn currentWorkspace;
} switchInfo;

strn
jsmnToStrn(char *j, jsmntok_t t) {
    return (strn) { &j[t.start], t.end-t.start };
}

inline int
tokStrEq(char *j, jsmntok_t t, char *s) {
    if(t.end - t.start != strlen(s))
        return 0;
    return memcmp(&j[t.start], s, t.end-t.start) ? 0 : 1;
}

int
skipTok(jsmntok_t *ts, int tlen, int toki) {
    int length = ts[toki].end - ts[toki].start;
    int nexti = toki+length/8; // 8 is magic, tuned based on testing.
    if(nexti>tlen)
        nexti = tlen-1;
    if(ts[nexti].start < ts[toki].end) {
        for(; nexti<tlen; nexti++) {
            jumpCount++;
            if(ts[nexti].start > ts[toki].end)
                break;
        }
    } else {
        for(; nexti>0; nexti--) {
            jumpCount++;
            if(ts[nexti].start < ts[toki].end)
                break;
        }
        nexti++;
    }
    return nexti;
}

switchInfo
getSwitchInfo(char *j, jsmntok_t *ts, int tlen, char *wanted) {
    int i = 0;
    if(ts[i].type != JSMN_ARRAY) {
        fprintf(stderr, "invalid json");
        exit(-1);
    }

    int gotOutputName = 0, gotOutputNodes = 0;
    int gotCurrent = 0, gotWanted = 0;
    switchInfo result;
    result.wantedState = 0;

    int currentWorkspace, focused = 0, visible = 0;
    jsmntok_t *name, *output;
    while(i<tlen) {
        if()
            break;
        if(i == tlen || ts[i].parent == 0) {
            if(name && output)
                if(visible && focused) {
                    result.currentOutput = jsmnToStrn(j, *output);
                    result.currentWorkspace = jsmnToStrn(j, *name);
                    gotCurrent = 1;
                    if(tokStrEq(j, *name, wanted))
                        return result;
                } else if(tokStrEq(j, *name, wanted)) {
                    result.wantedOutput = jsmnToStrn(j, *output);
                    result.wantedState = visible ? WS_Visible : WS_NotVisible;
                    gotWanted = 1;
                }
            if(gotCurrent && (gotWanted || i==tlen))
                return result;
            else if(i==tlen)
                panic("panic, didn't get current workspace");
                
            currentWorkspace = i;
            focused = 0;
            visible = 0;
            name = 0;
            output = 0;
        } else if(ts[i].parent == currentWorkspace && ts[i].type == JSMN_STRING) {
            if(tokStrEq(j, ts[i], "focused") && ts[i].size == 1) {
                i++;
                if(ts[i].type != JSMN_PRIMITIVE)
                    panic("panic at focused parse");
                if(j[ts[i].start] == 't')
                    focused = 1;
            } else if(tokStrEq(j, ts[i], "visible") && ts[i].size == 1) {
                i++;
                if(ts[i].type != JSMN_PRIMITIVE)
                    panic("panic at visible parse");
                if(j[ts[i].start] == 't')
                    visible = 1;
            } else if(tokStrEq(j, ts[i], "name") && ts[i].size == 1) {
                i++;
                if(ts[i].type != JSMN_STRING)
                    panic("panic at name parse");
                name = &ts[i];
            }
        }
    }
    return result;
}

int
testSkip(jsmntok_t *ts, int len, int i) {
    int sane, test;
    for(sane=i; sane<len && ts[i].end > ts[sane].start; sane++);
    test = skipTok(ts, len, i);
    return test == sane;
}

int
main(int argc, char **argv) {
    if(argc != 2) {
        fputs("improper number of arguments", stderr);
        return -1;
    }
    char *wantedWorkspace = argv[1];
    s = socket(AF_UNIX, SOCK_STREAM, 0);
    if (s == -1) {
        perror("socket");
        return -1;
    }
    char *sockPath;
    if(!(sockPath = getenv("I3SOCK"))) {
        fputs("I3SOCK variable not present", stderr);
        return -1;
    }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sockPath, sizeof(addr.sun_path) - 1);
    addr.sun_path[sizeof(addr.sun_path) - 1] = 0;

    int cr = connect(s, (const struct sockaddr *) &addr, sizeof(addr));
    if(cr == -1) {
        perror("socket");
        return -1;
    }
    
    sendHeader();
    sendInt(0);
    sendInt(4);
    int32_t replyLen = getResponseLen();
    char *reply = calloc(sizeof(char), replyLen);
    jsmntok_t *replyTok = calloc(sizeof(jsmntok_t), replyLen);
    ssize_t rr = read(s, reply, replyLen);
    if(rr <= 0) {
        perror("read error");
        return -1;
    }
    jsmn_parser parser;
    jsmn_init(&parser);
    int pr = jsmn_parse(&parser, reply, replyLen, replyTok, replyLen);
    if(pr < 0) {
        fprintf(stderr, "parse error %d", pr);
        return -1;
    }
    
    // printToks(reply, replyTok, pr);
    int i;
    for(i=0; i<pr; i++)
        if(replyTok[i].parent == 0)
            break;
    for(i=0; i<pr; i++) {
        if(!testSkip(replyTok, pr, i)) {
            panic("uh oh\n");
        }
    }
    printf("%d\n", jumpCount);
    return 0;
    
    switchInfo si = getSwitchInfo(reply, replyTok, pr, argv[1]);

    int cmdMaxLen = 512;
    int32_t cmdLen;
    char *cmd = malloc(cmdMaxLen);
    // switch(si.wantedState) {
    // case WS_DoesntExist:
    //     cmdLen = snprintf(cmd, cmdMaxLen, "workspace %s", wantedWorkspace);
    //     break;
    // case WS_NotVisible:
    //     cmdLen = snprintf(cmd, cmdMaxLen, "[workspace=\"%s\"] move workspace to output %.*s; workspace %s",
    //         wantedWorkspace, si.currentOutput.len, si.currentOutput.s,
    //         wantedWorkspace);
    //     break;
    // case WS_Visible:
    //     cmdLen = snprintf(cmd, cmdMaxLen,
    //         "[workspace=\"%s\"] move workspace to output %.*s; [workspace=\"%.*s\"] move workspace to output %.*s; workspace %s",
    //         wantedWorkspace, si.currentOutput.len, si.currentOutput.s,
    //         si.currentWorkspace.len, si.currentWorkspace.s, si.wantedOutput.len, si.wantedOutput.s,
    //         wantedWorkspace
    //         );
    //     break;
    // }
    if(cmdLen >= cmdMaxLen)
        panic("built command is too long\n");
    sendHeader();
    sendInt(cmdLen);
    sendInt(0);
    write(s, cmd, cmdLen);
}
