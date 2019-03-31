#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
#import <googleapis/Operations.pbobjc.h>
#endif

#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import <ProtoRPC/ProtoService.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriteable.h>
#import <RxLibrary/GRXWriter.h>
#endif

@class CancelOperationRequest;
@class DeleteOperationRequest;
@class GPBEmpty;
@class GetOperationRequest;
@class ListOperationsRequest;
@class ListOperationsResponse;
@class Operation;

#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
  #import <googleapis/Annotations.pbobjc.h>
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Any.pbobjc.h>
#else
  #import "google/protobuf/Any.pbobjc.h"
#endif
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Empty.pbobjc.h>
#else
  #import "google/protobuf/Empty.pbobjc.h"
#endif
  #import <googleapis/Status.pbobjc.h>
#endif

@class GRPCProtoCall;
@class GRPCUnaryProtoCall;
@class GRPCStreamingProtoCall;
@class GRPCCallOptions;
@protocol GRPCProtoResponseHandler;


NS_ASSUME_NONNULL_BEGIN

@protocol Operations2 <NSObject>

#pragma mark GetOperation(GetOperationRequest) returns (Operation)

/**
 * Gets the latest state of a long-running operation.  Clients may use this
 * method to poll the operation result at intervals as recommended by the API
 * service.
 */
- (GRPCUnaryProtoCall *)getOperationWithMessage:(GetOperationRequest *)message responseHandler:(id<GRPCProtoResponseHandler>)handler callOptions:(GRPCCallOptions *_Nullable)callOptions;

#pragma mark ListOperations(ListOperationsRequest) returns (ListOperationsResponse)

/**
 * Lists operations that match the specified filter in the request. If the
 * server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 */
- (GRPCUnaryProtoCall *)listOperationsWithMessage:(ListOperationsRequest *)message responseHandler:(id<GRPCProtoResponseHandler>)handler callOptions:(GRPCCallOptions *_Nullable)callOptions;

#pragma mark CancelOperation(CancelOperationRequest) returns (Empty)

/**
 * Starts asynchronous cancellation on a long-running operation.  The server
 * makes a best effort to cancel the operation, but success is not
 * guaranteed.  If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.  Clients may use
 * [Operations.GetOperation] or other methods to check whether the
 * cancellation succeeded or the operation completed despite cancellation.
 */
- (GRPCUnaryProtoCall *)cancelOperationWithMessage:(CancelOperationRequest *)message responseHandler:(id<GRPCProtoResponseHandler>)handler callOptions:(GRPCCallOptions *_Nullable)callOptions;

#pragma mark DeleteOperation(DeleteOperationRequest) returns (Empty)

/**
 * Deletes a long-running operation.  It indicates the client is no longer
 * interested in the operation result. It does not cancel the operation.
 */
- (GRPCUnaryProtoCall *)deleteOperationWithMessage:(DeleteOperationRequest *)message responseHandler:(id<GRPCProtoResponseHandler>)handler callOptions:(GRPCCallOptions *_Nullable)callOptions;

@end

@protocol Operations <NSObject>

#pragma mark GetOperation(GetOperationRequest) returns (Operation)

/**
 * Gets the latest state of a long-running operation.  Clients may use this
 * method to poll the operation result at intervals as recommended by the API
 * service.
 */
- (void)getOperationWithRequest:(GetOperationRequest *)request handler:(void(^)(Operation *_Nullable response, NSError *_Nullable error))handler;

/**
 * Gets the latest state of a long-running operation.  Clients may use this
 * method to poll the operation result at intervals as recommended by the API
 * service.
 */
- (GRPCProtoCall *)RPCToGetOperationWithRequest:(GetOperationRequest *)request handler:(void(^)(Operation *_Nullable response, NSError *_Nullable error))handler;


#pragma mark ListOperations(ListOperationsRequest) returns (ListOperationsResponse)

/**
 * Lists operations that match the specified filter in the request. If the
 * server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 */
- (void)listOperationsWithRequest:(ListOperationsRequest *)request handler:(void(^)(ListOperationsResponse *_Nullable response, NSError *_Nullable error))handler;

/**
 * Lists operations that match the specified filter in the request. If the
 * server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 */
- (GRPCProtoCall *)RPCToListOperationsWithRequest:(ListOperationsRequest *)request handler:(void(^)(ListOperationsResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark CancelOperation(CancelOperationRequest) returns (Empty)

/**
 * Starts asynchronous cancellation on a long-running operation.  The server
 * makes a best effort to cancel the operation, but success is not
 * guaranteed.  If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.  Clients may use
 * [Operations.GetOperation] or other methods to check whether the
 * cancellation succeeded or the operation completed despite cancellation.
 */
- (void)cancelOperationWithRequest:(CancelOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;

/**
 * Starts asynchronous cancellation on a long-running operation.  The server
 * makes a best effort to cancel the operation, but success is not
 * guaranteed.  If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.  Clients may use
 * [Operations.GetOperation] or other methods to check whether the
 * cancellation succeeded or the operation completed despite cancellation.
 */
- (GRPCProtoCall *)RPCToCancelOperationWithRequest:(CancelOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;


#pragma mark DeleteOperation(DeleteOperationRequest) returns (Empty)

/**
 * Deletes a long-running operation.  It indicates the client is no longer
 * interested in the operation result. It does not cancel the operation.
 */
- (void)deleteOperationWithRequest:(DeleteOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;

/**
 * Deletes a long-running operation.  It indicates the client is no longer
 * interested in the operation result. It does not cancel the operation.
 */
- (GRPCProtoCall *)RPCToDeleteOperationWithRequest:(DeleteOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;


@end


#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
/**
 * Basic service implementation, over gRPC, that only does
 * marshalling and parsing.
 */
@interface Operations : GRPCProtoService<Operations, Operations2>
- (instancetype)initWithHost:(NSString *)host callOptions:(GRPCCallOptions *_Nullable)callOptions NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithHost:(NSString *)host;
+ (instancetype)serviceWithHost:(NSString *)host callOptions:(GRPCCallOptions *_Nullable)callOptions;
+ (instancetype)serviceWithHost:(NSString *)host;
@end
#endif

NS_ASSUME_NONNULL_END

