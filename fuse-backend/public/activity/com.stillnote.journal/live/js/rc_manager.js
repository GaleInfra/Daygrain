
var SingleJsonMsgMessage;
var lastIMToken = "";
//融云是否初始化中
var isInitRongCloud = false;
    async function initRongCloud(appKey, token, areaCodeStr, callback) {
        if(isInitRongCloud && lastIMToken == token){
            return;
        }
        isInitRongCloud = true;
        await _initRongCloud(false,appKey, token, areaCodeStr, callback);
    }

    async function _initRongCloud(isReInit,appKey, token, areaCodeStr, callback) {
        
        lastIMToken = token;
        var areaCode = 1;
        if(areaCodeStr == "BJ"){
            areaCode = 1;
        }else if(areaCodeStr == "SG"){
            areaCode = 2;   
        }else if(areaCodeStr == "NA"){
            areaCode = 3;   
        }else if(areaCodeStr == "SG_B"){
            areaCode = 4;   
        }else if(areaCodeStr == "SA"){
            areaCode = 5;   
        }
        try {
            // Configure RongCloud SDK
            RongIMLib.init({
                appkey: appKey,
                areaCode: areaCode,
            });

            //注册自定义消息
            SingleJsonMsgMessage = RongIMLib.registerMessageType('LC:SingleJsonMsg', true, true, [], false);
            const NoneFlagMessage = RongIMLib.registerMessageType('LC:NoneFlagMsg', false, false, [], false);
            const HyperLinkMessage = RongIMLib.registerMessageType('LC:HyperLinkMsg', true, true, [], false);
            await connectRongCloud(appKey, token, areaCodeStr, callback);
            isInitRongCloud = false;
           
           
        } catch (error) {
            console.error('RongCloud initialization failed', error);
        //等待1秒后重试
            setTimeout(() => {
                if(lastIMToken == token){
                    _initRongCloud(appKey, token, areaCodeStr, callback);
                }
                
            }, 1000);
        }
        return true;
    }
    //融云链接
    async function connectRongCloud(appKey, token, areaCodeStr, callback) {
    
        await RongIMLib.connect(token).then((res) => {
            if (res.code === 0) {
                console.log(res.data.userId)
                callback.onSuccess(res.data.userId);
            }else{
                // callback.onError(res.code);
                setTimeout(() => {
                    if(lastIMToken == token){
                        connectRongCloud(appKey, token, areaCodeStr, callback);
                    }
                    
                }, 1000);
            }
        }).catch(error => {
            console.log(error);
            //等待1秒后重试
            setTimeout(() => {
                if(lastIMToken == token){
                    connectRongCloud(appKey, token, areaCodeStr, callback);
                }
                
            }, 1000);
        })
 
    }

    async function getTotalUnreadCount(callback) {

        let includeMuted = false;
        let conversationTypes = [RongIMLib.ConversationType.PRIVATE, RongIMLib.ConversationType.GROUP];
        RongIMLib.getTotalUnreadCount(includeMuted, conversationTypes).then(res => {
          if (res.code === 0) {
            console.log("Total unread conversations: code:"+res.code, res.data);
            callback.onSuccess(res.data);
          } else {
            console.log("Total unread conversations: code:"+res.code, res.msg);
            callback.onError(new Error(res.msg));
          }
        }).catch(error => {
          console.log("Total unread conversations: error", error);
          callback.onError(error);
        });
    }

    async function getConversation(targetId, channelId = null,callback) {
        RongIMLib.getConversation( { conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId}).then((conversation) => {
                console.log('Conversation retrieved', conversation);
                // //遍历 data 中的数据 latestMessage 改为 lastMessage 字段
                // if (conversation.latestMessage) {
                //     conversation.lastMessage = conversation.latestMessage;
                //     delete conversation.latestMessage;
                // }

               var conversations = conversation.data;

                // if(conversations.latestMessage != null && conversations.latestMessage.messageType == "RC:CmdMsg"){
                //     conversations.latestMessage = null;
                // }


                callback.onSuccess(conversations);
            })
            .catch((error) => {
                console.error('Failed to retrieve conversation', error);
                callback.onError(error);
            });

        return 0;
    }

    async function getConversations(channelId, startTime, count, callback) {
        RongIMLib.getConversationList({
            count: count, 
            startTime: startTime
        }, channelId)
            .then((conversations) => {
                console.log('Conversation list retrieved', conversations);
                // //遍历 data 中的数据 latestMessage 改为 lastMessage 字段
                // conversations.data.forEach((conversation) => {
                //     // if (conversation.latestMessage) {
                //     //     if(conversation.latestMessage != null && conversation.latestMessage.messageType == "RC:CmdMsg"){
                //     //         conversation.latestMessage = null;
                //     //     }
                //     // }
                // });
                //conversations.data 过滤 targetId 不是纯数字的数据
                conversations.data = conversations.data.filter((conversation) => {
                    // 过滤会话列表:
                    // 1. 保留targetId长度小于11的会话
                    // 2. 对于更长的targetId，只保留纯数字的会话
                    if(conversation.targetId.length < 11){
                        //清空消息数
                        clearMessagesUnreadStatus(conversation.targetId, (res) => {});
                        return false
                    }
                    return !isNaN(conversation.targetId);
                });

                callback.onSuccess(conversations.data);
            })
            .catch((error) => {
                console.error('Failed to retrieve conversation list', error);
                callback.onError(error);
            });
        return 0;
    }

    //获取置顶会话列表
    async function getTopConversations( callback) {
        const conversationTypes = [RongIMLib.ConversationType.PRIVATE];

        try {
            let src = await RongIMLib.getTopConversationList(conversationTypes);
            if(src.code === 0){
                if(src.data.length > 0){
                    //查询最新消息
                    await Promise.all(src.data.map(async (item) => {
                        
                        let conversation = await RongIMLib.getConversation( { conversationType: RongIMLib.ConversationType.PRIVATE,
                            targetId: item.targetId});
                            // if(conversation.latestMessage != null && conversation.latestMessage.messageType == "RC:CmdMsg"){
                                
                            // }else{
                                item.latestMessage = conversation.data.latestMessage;
                            // }
                        
                        return item;
                    }));
                    callback.onSuccess(src.data);
                }


            }else{
                callback.onError(src.msg);
            }
        } catch (error) {
            callback.onError(error);
        }
            
        return 0;
    }

    ///获取历史消息
    async function getHistoryMessages(targetId, channelId, count,sentTime, order, callback) {

        let conversation = {
            conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId,
        };
        
        // 从当前时间开始向前查询
        let option = {
            timestamp: sentTime,
            count: count,
            order: order,
        };
        
        RongIMLib.getHistoryMessages(conversation, option).then(res => {
            if (res.code === 0) {
                console.log(res.data.list);
                console.log(res.data.hasMore);
                callback.onSuccess(res.data.list);
            } else {
                console.log(res.code, res.msg);
                callback.onError(new Error(res.msg));
            }
        });

        return 0;
    }

    ///获取历史消息
    async function getHistoryMessages(targetId, channelId, count,sentTime, order, callback) {

        let conversation = {
            conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId,
        };
        
        // 从当前时间开始向前查询
        let option = {
            timestamp: sentTime,
            count: count,
            order: order,
        };
        
         await RongIMLib.getHistoryMessages(conversation, option).then(res => {
            if (res.code === 0) {
                console.log(res.data.list);
                console.log(res.data.hasMore);
                callback.onSuccess(res.data.list);
            } else {
                console.log(res.code, res.msg);
                callback.onError(new Error(res.msg));
            }
        });

        return 0;
    }

    //删除消息
    async function deleteMessages(targetId, channelId, messages, callback) {
        let conversation = {
            conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId,
        };
        RongIMLib.deleteMessages(conversation, messages).then(res => {
            if (res.code === 0) {
                console.log('删除成功');
                callback.onSuccess(res.data);
            } else {
                console.log(res.code, res.msg);
                callback.onError(new Error(res.msg));
            }
        }).catch(error => {
            console.log(error);
            callback.onError(error);
        });
    }

    //SingleJsonMsgMessage
    async function sendSingleJsonMsgMessage(targetId, content, extra,contentType, callback) {
        // 构建要发送的自定义消息
        let message = new SingleJsonMsgMessage({ content: content, contentType: contentType, extra: extra });
        // 配置属性
        const options = {
            // 消息发送前的回调，可以使用此回调返回的 message 用于列表渲染
            onSendBefore: (message) => {
            console.log('消息发送前的回调', message)
            callback.onSendBefore(message);
            }
        }
        // 发送消息
        RongIMLib.sendMessage({
            conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId,
            options: options
        }, message).then(res => {
        if (res.code === 0) {
            console.log(res.code, res.data);
            callback.onSuccess(res.data);
        } else {
            console.log(res.code);
            callback.onError(res.code);
        }
        }).catch(error => {
            console.log(error);
            callback.onError(-1);
        });
    }

   //发送文本消息
   async function sendTextMessage(targetId, messageId, content, callback) {
    // 构建要发送的文本消息
    let message = new RongIMLib.TextMessage({ content: content });

    let options = {
        messageId: messageId,
         // 消息发送前的回调，可以使用此回调返回的 message 用于列表渲染
         onSendBefore: (message) => {
            console.log('消息发送前的回调', message)
            callback.onSendBefore(message);
            }
    }
    // 发送消息
    RongIMLib.sendMessage({
        conversationType: RongIMLib.ConversationType.PRIVATE,
        targetId: targetId
    }, message, options).then(res => {
    if (res.code === 0) {
        console.log(res.code, res.data);
        callback.onSuccess(res.data);
    } else {
        console.log(res.code);
        callback.onError(new Error(res.msg));
    }
    }).catch(error => {
        console.log(error);
        callback.onError(error);
    });
   }



    //发送图片消息
    async function sendImageMessage(targetId, file, messageId, sendId, nickname, avatar, callback) {
        let conversation = {
            conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId
          };
          let msgBody = {
            file ,// 待上传文件
            user: { id: sendId, name: nickname, portraitUri: avatar, extra: '' },
          };
          let hooks = {
            onProgress (progress) {},  // 上传进度监听，可选
            onComplete (fileInfo) { // 上传完成时的回调钩子，可选
              console.log(fileInfo.url) // 文件存储地址
              // 如果需要构建自定义消息，return new ABCMesssage('')
              // ABCMesssage 定义通过自定义消息实现 `const ABCMesssage = RongIMLib.registerMessageType(...)`
              // 无 return 返回值的情况下，SDK 默认发送 FileMessage
            }
          }
          let options = {
            contentDisposition: 'inline', // 'inline' | 'attachment' , 使用 aws 上传时返回链接在浏览器中的展示形式
            messageId: messageId,
            // 消息发送前的回调，可以使用此回调返回的 message 用于列表渲染
         onSendBefore: (message) => {
            console.log('消息发送前的回调', message)
            callback.onSendBefore(message);
            }
          };
          
          RongIMLib.sendImageMessage(
            conversation,
            msgBody,
            hooks,
            options
          ).then(({ code, data: message }) => {
            if (code === 0) {
              // 发送成功
              callback.onSuccess(message);
            }else{
              callback.onError(message);
            }
          }).catch(error => {
            console.log(error);
            callback.onError(error);
          });
    }

    //发送图片消息
    async function sendVoiceMessage(targetId, file, messageId, sendId, nickname, avatar, callback) {
        let conversation = {
            conversationType: RongIMLib.ConversationType.PRIVATE,
            targetId: targetId
          };
          let msgBody = {
            file ,// 待上传文件
            user: { id: sendId, name: nickname, portraitUri: avatar, extra: '' },
          };
          let hooks = {
            onProgress (progress) {},  // 上传进度监听，可选
            onComplete (fileInfo) { // 上传完成时的回调钩子，可选
              console.log(fileInfo.url) // 文件存储地址
              // 如果需要构建自定义消息，return new ABCMesssage('')
              // ABCMesssage 定义通过自定义消息实现 `const ABCMesssage = RongIMLib.registerMessageType(...)`
              // 无 return 返回值的情况下，SDK 默认发送 FileMessage
            }
          }
          let options = {
            contentDisposition: 'inline', // 'inline' | 'attachment' , 使用 aws 上传时返回链接在浏览器中的展示形式
            messageId: messageId,
            // 消息发送前的回调，可以使用此回调返回的 message 用于列表渲染
         onSendBefore: (message) => {
            console.log('消息发送前的回调', message)
            callback.onSendBefore(message);
            }
          };
          
          RongIMLib.sendHQVoiceMessage(
            conversation,
            msgBody,
            hooks,
            options
          ).then(({ code, data: message }) => {
            if (code === 0) {
              // 发送成功
              callback.onSuccess(message);
            }else{
              callback.onError(message);
            }
          }).catch(error => {
            console.log(error);
            callback.onError(error);
          });
    }

    //设置消息监听
    async function setMessageListener(callback) {
        let Events = RongIMLib.Events
        let listener = (evt) => {
        console.log(evt.messages);
        callback.onSuccess(evt.messages);
        };
        RongIMLib.addEventListener(Events.MESSAGES, listener);
    }

    //清空未读消息
    async function clearMessagesUnreadStatus(targetId,callback) {
        const conversationType = RongIMLib.ConversationType.PRIVATE;

        RongIMLib.clearMessagesUnreadStatus({ conversationType, targetId }).then(res => {
        if (res.code === 0) {
            console.log(res.code)
            callback.onSuccess(res.data);
        } else {
            console.log(res.code, res.msg)
            callback.onError(new Error(res.msg));
        }
        }).catch(error => {
            console.log(error);
            callback.onError(error);
        });
    }

    //删除会话
    async function removeConversation(targetId, callback) {
        const conversationType = RongIMLib.ConversationType.PRIVATE;

        RongIMLib.removeConversation({
            conversationType,
            targetId: targetId,
        }).then(res => {
            // 删除指定会话成功
            if(res.code === 0){
                console.log(res.code)
                callback.onSuccess(res.data);
            } else {
                console.log(res.code, res.msg)
                callback.onError(res.code);
            }
        }).catch(error => {
            console.log(error);
            callback.onError(-1);
        })
    }

    //设置会话为置顶
    async function changeConversationTopStatus(targetId, top, callback) {
        const conversationType = RongIMLib.ConversationType.PRIVATE;
        const isTop = top;

        RongIMLib.setConversationToTop({
            conversationType,
            targetId,
        }, isTop).then(({code}) => {
            // 设置会话置顶成功
            if( !code ){
                callback.onSuccess(targetId);
            }else{
                callback.onError(code);
            }
        }).catch(error => {
            console.log(error);
            callback.onError(-1);
        })
    }

    //拉黑
    async function addToBlacklist(userId, callback) {
        RongIMLib.addToBlacklist(userId).then(res => {
            console.log(res.code)
            if(res.code === 0){
                callback.onSuccess(res.data);
            }else{
                callback.onError(res.code);
            }
        }).catch(error => {
            console.log(error);
            callback.onError(-1);
        })
    }

    //从黑名单移除
    async function removeFromBlacklist(userId, callback) {

        RongIMLib.removeFromBlacklist(userId).then(res => {
            console.log(res.code)
            if(res.code === 0){
                callback.onSuccess(res.data);
            }else{
                callback.onError(res.code);
            }
        }).catch(error => {
            console.log(error);
            callback.onError(-1);
        })
    }



// Expose methods globally
window.initRongCloud = initRongCloud;
window.getTotalUnreadCount = getTotalUnreadCount;
window.getConversation = getConversation;
window.getConversations = getConversations;
window.setMessageListener = setMessageListener;
window.getHistoryMessages = getHistoryMessages;
window.deleteMessages = deleteMessages;
window.sendImageMessage = sendImageMessage;