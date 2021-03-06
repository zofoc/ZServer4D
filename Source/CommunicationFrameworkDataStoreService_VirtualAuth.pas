﻿{ ****************************************************************************** }
{ * DataStore Service with VirtualAuth                                         * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ ****************************************************************************** }
(*
  update history
*)
unit CommunicationFrameworkDataStoreService_VirtualAuth;

interface

{$I zDefine.inc}


uses CoreClasses, ListEngine, UnicodeMixedLib, DataFrameEngine, MemoryStream64, CommunicationFramework, TextDataEngine,
  DoStatusIO, Cadencer, NotifyObjectBase, PascalStrings, CoreCipher, ZDBEngine, ItemStream, CoreCompress,
  {$IFNDEF FPC}
  SysUtils, JsonDataObjects,
  {$ENDIF}
  CommunicationFrameworkDoubleTunnelIO_VirtualAuth, CommunicationFrameworkDataStoreServiceCommon, ZDBLocalManager;

type
  TDataStoreService_VirtualAuth                      = class;
  TDataStoreService_PeerClientSendTunnel_VirtualAuth = class;

  TDataStoreService_PeerClientRecvTunnel_VirtualAuth = class(TPeerClientUserDefineForRecvTunnel_VirtualAuth)
  private
    FPostPerformaceCounter: Integer;
    FLastPostPerformaceTime: TTimeTickValue;
    FPostCounterOfPerSec: Double;
  public
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;

    procedure Progress; override;

    function SendTunnelDefine: TDataStoreService_PeerClientSendTunnel_VirtualAuth;
    property PostCounterOfPerSec: Double read FPostCounterOfPerSec;
  end;

  TDataStoreService_PeerClientSendTunnel_VirtualAuth = class(TPeerClientUserDefineForSendTunnel_VirtualAuth)
  public
    constructor Create(AOwner: TPeerIO); override;
    destructor Destroy; override;

    function RecvTunnelDefine: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  end;

  TDataStoreService_VirtualAuth = class(TCommunicationFramework_DoubleTunnelService_VirtualAuth, IZDBLocalManagerNotify)
  private type
    POnStorePosTransformTrigger_VirtualAuth = ^TOnStorePosTransformTrigger_VirtualAuth;

    TOnStorePosTransformTrigger_VirtualAuth = record
      Client_SendTunnel_ID: Cardinal;
      BackcallPtr: UInt64;
    end;
  private
    FZDBLocal: TZDBLocalManager;
    FQueryCallPool: THashObjectList;
    FPerQueryPipelineDelayFreeTime: Double;
  protected
    procedure CreateQuery(pipe: TZDBPipeline); virtual;
    procedure QueryFragmentData(pipe: TZDBPipeline; FragmentSource: TMemoryStream64); virtual;
    procedure QueryDone(pipe: TZDBPipeline); virtual;
    procedure StorePosTransform(const Data: Pointer; const TransformBuff: PZDBStorePosTransformArray);
    procedure CreateDB(ActiveDB: TZDBStoreEngine); virtual;
    procedure CloseDB(ActiveDB: TZDBStoreEngine); virtual;
    procedure InsertData(Sender: TZDBStoreEngine; InsertPos: Int64; buff: TCoreClassStream; id: Cardinal; CompletePos: Int64); virtual;
    procedure AddData(Sender: TZDBStoreEngine; buff: TCoreClassStream; id: Cardinal; CompletePos: Int64); virtual;
    procedure ModifyData(Sender: TZDBStoreEngine; const StorePos: Int64; buff: TCoreClassStream); virtual;
    procedure DeleteData(Sender: TZDBStoreEngine; const StorePos: Int64); virtual;
  protected
    procedure DownloadQueryFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
    procedure DownloadQueryWithIDFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);

    procedure UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth); override;

    procedure Command_InitDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CloseDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_CopyDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompressDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_ReplaceDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_ResetData(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_QueryDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_DownloadDB(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_DownloadDBWithID(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_RequestDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_RequestFastDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_FastPostCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
    procedure Command_FastInsertCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
    procedure Command_FastModifyCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);

    procedure Command_CompletedPostAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedInsertAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedModifyAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_DeleteData(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    procedure Command_GetDBList(Sender: TPeerIO; InData, OutData: TDataFrameEngine); virtual;
    procedure Command_GetQueryList(Sender: TPeerIO; InData, OutData: TDataFrameEngine); virtual;
    procedure Command_GetQueryState(Sender: TPeerIO; InData, OutData: TDataFrameEngine); virtual;
    procedure Command_QueryStop(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_QueryPause(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_QueryPlay(Sender: TPeerIO; InData: TDataFrameEngine); virtual;

    // send client command
    procedure Send_CompletedFragmentBigStream(pipe: TTDataStoreService_DBPipeline);
    procedure Send_CompletedQuery(pipe: TTDataStoreService_DBPipeline);
    procedure Send_CompletedDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
    procedure Send_CompletedFastDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
    procedure Send_CompletedStorePosTransform(ASendCli: TPeerIO; const BackcallPtr: UInt64; const TransformBuff: PZDBStorePosTransformArray);
  public
    constructor Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkServer);
    destructor Destroy; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    procedure Progress; override;
    procedure CadencerProgress(Sender: TObject; const deltaTime, newTime: Double); override;

    function GetDataStoreUserDefine(RecvCli: TPeerIO): TDataStoreService_PeerClientRecvTunnel_VirtualAuth;

    function RegisterQueryCall(cName: SystemString): TTDataStoreService_QueryCall;
    procedure UnRegisterQueryCall(cName: SystemString);
    function GetRegistedQueryCall(cName: SystemString): TTDataStoreService_QueryCall;

    function PostCounterOfPerSec: Double;

    property ZDBLocal: TZDBLocalManager read FZDBLocal;
    property QueryCallPool: THashObjectList read FQueryCallPool;
    property PerQueryPipelineDelayFreeTime: Double read FPerQueryPipelineDelayFreeTime write FPerQueryPipelineDelayFreeTime;
  end;

  TDataStoreClient_VirtualAuth = class(TCommunicationFramework_DoubleTunnelClient_VirtualAuth)
  private
    procedure Command_CompletedFragmentBigStream(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedQuery(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedFastDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
    procedure Command_CompletedStorePosTransform(Sender: TPeerIO; InData: TDataFrameEngine); virtual;
  public
    constructor Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkClient);
    destructor Destroy; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    procedure Progress; override;

    procedure InitDB(inMem: Boolean; dbN: SystemString); virtual;
    procedure CloseDB(dbN: SystemString; CloseAndDeleted: Boolean); virtual;

    procedure CopyDB(dbN, copyToN: SystemString); overload;
    procedure CopyDB(dbN, copyToN: SystemString; const BackcallPtr: PStorePosTransformNotify); overload;
    procedure CopyDB_C(dbN, copyToN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall); overload;
    procedure CopyDB_M(dbN, copyToN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure CopyDB_P(dbN, copyToN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc); overload;
    {$ENDIF FPC}
    //
    procedure CompressDB(dbN: SystemString); overload;
    procedure CompressDB(dbN: SystemString; const BackcallPtr: PStorePosTransformNotify); overload;
    procedure CompressDB_C(dbN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall); overload;
    procedure CompressDB_M(dbN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure CompressDB_P(dbN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc); overload;
    {$ENDIF FPC}
    //
    procedure ReplaceDB(dbN, ReplaceN: SystemString); virtual;
    procedure ResetData(dbN: SystemString); virtual;

    procedure QuietQueryDB(RegistedQueryName: SystemString; ReverseQuery: Boolean; dbN, outDBN: SystemString; MaxWait: Double; MaxQueryResult: Int64); virtual;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64; BackcallPtr: PDataStoreClientQueryNotify; RemoteParams: THashVariantList); overload; virtual;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList; // service ref remote parameter
      OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList;                                           // service ref remote parameter
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnQueryCall: TUserFillQueryDataCall; OnDoneCall: TUserQueryDoneNotifyCall); overload;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList; // service ref remote parameter
      OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList;                                           // service ref remote parameter
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnQueryMethod: TUserFillQueryDataMethod; OnDoneMethod: TUserQueryDoneNotifyMethod); overload;

    {$IFNDEF FPC}
    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList; // service ref remote parameter
      OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload;

    procedure QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
      fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
      RemoteParams: THashVariantList;                                           // service ref remote parameter
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnQueryProc: TUserFillQueryDataProc; OnDoneProc: TUserQueryDoneNotifyProc); overload;
    {$ENDIF}
    //
    //
    procedure QueryDB(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;
    procedure QueryDB(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure QueryDB(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload;
    {$ENDIF}
    //
    //
    procedure DownloadDB(ReverseQuery: Boolean; dbN: SystemString; BackcallPtr: PDataStoreClientQueryNotify); overload; virtual;
    procedure DownloadDB(ReverseQuery: Boolean; dbN: SystemString; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;
    procedure DownloadDB(ReverseQuery: Boolean; dbN: SystemString; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure DownloadDB(ReverseQuery: Boolean; dbN: SystemString; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload;
    {$ENDIF}
    //
    procedure DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; BackcallPtr: PDataStoreClientQueryNotify); overload; virtual;
    procedure DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall); overload;
    procedure DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc); overload;
    {$ENDIF}
    //
    procedure BeginAssembleStream; virtual;

    procedure RequestDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify); virtual;
    procedure DownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall); overload;
    procedure DownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure DownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc); overload;
    {$ENDIF}
    procedure DownloadAssembleStream(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneCall: TUserDownloadDoneNotifyCall); overload;
    procedure DownloadAssembleStream(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneMethod: TUserDownloadDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure DownloadAssembleStream(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneProc: TUserDownloadDoneNotifyProc); overload;
    {$ENDIF}
    //
    //
    procedure RequestFastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify); virtual;
    procedure FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall); overload;
    procedure FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc); overload;
    {$ENDIF}
    procedure FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneCall: TUserDownloadDoneNotifyCall); overload;
    procedure FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneMethod: TUserDownloadDoneNotifyMethod); overload;
    {$IFNDEF FPC}
    procedure FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64;
      UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
      OnDoneProc: TUserDownloadDoneNotifyProc); overload;
    {$ENDIF}
    //
    // safe post support
    procedure PostAssembleStream(dbN: SystemString; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure PostAssembleStreamCopy(dbN: SystemString; Stream: TCoreClassStream; dID: Cardinal);
    procedure PostAssembleStream(dbN: SystemString; DataSource: TDataFrameEngine); overload;
    procedure PostAssembleStream(dbN: SystemString; DataSource: THashVariantList); overload;
    procedure PostAssembleStream(dbN: SystemString; DataSource: TSectionTextData); overload;
    {$IFNDEF FPC} procedure PostAssembleStream(dbN: SystemString; DataSource: TJsonObject); overload; virtual; {$ENDIF}
    procedure PostAssembleStream(dbN: SystemString; DataSource: TPascalString); overload;
    //
    // safe insert support
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure InsertAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream; dID: Cardinal);
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
    {$IFNDEF FPC} procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    // safe modify support
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; DoneTimeFree: Boolean); overload; virtual;
    procedure ModifyAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream);
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
    {$IFNDEF FPC} procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    procedure GetPostAssembleStreamState(OnResult: TStreamMethod); overload; virtual;
    {$IFNDEF FPC}
    procedure GetPostAssembleStreamState(OnResult: TStreamProc); overload; virtual;
    {$ENDIF}
    //
    procedure EndAssembleStream; virtual;
    //
    procedure DeleteData(dbN: SystemString; dStorePos: Int64); virtual;
    //
    // fast post support
    procedure FastPostCompleteBuffer(dbN: SystemString; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure FastPostCompleteBufferCopy(dbN: SystemString; Stream: TCoreClassStream; dID: Cardinal);
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TDataFrameEngine); overload;
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: THashVariantList); overload;
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TSectionTextData); overload;
    {$IFNDEF FPC} procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TJsonObject); overload; virtual; {$ENDIF}
    procedure FastPostCompleteBuffer(dbN: SystemString; DataSource: TPascalString); overload;
    //
    // fast insert support
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure FastInsertCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream; dID: Cardinal);
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
    {$IFNDEF FPC} procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    // fast modify support
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean); overload; virtual;
    procedure FastModifyCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream; dID: Cardinal);
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine); overload;
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList); overload;
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData); overload;
    {$IFNDEF FPC} procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject); overload; {$ENDIF}
    procedure FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString); overload;
    //
    //
    procedure GetDBList(OnResult: TStreamMethod); overload; virtual;
    procedure GetQueryList(OnResult: TStreamMethod); overload; virtual;
    procedure GetQueryState(pipeN: SystemString; OnResult: TStreamMethod); overload; virtual;
    procedure QueryStop(pipeN: SystemString); virtual;
    procedure QueryPause(pipeN: SystemString); virtual;
    procedure QueryPlay(pipeN: SystemString); virtual;
    //
    {$IFNDEF FPC}
    procedure GetDBList(OnResult: TStreamProc); overload; virtual;
    procedure GetQueryList(OnResult: TStreamProc); overload; virtual;
    procedure GetQueryState(pipeN: SystemString; OnResult: TStreamProc); overload; virtual;
    {$ENDIF}
  end;

implementation


constructor TDataStoreService_PeerClientRecvTunnel_VirtualAuth.Create(AOwner: TPeerIO);
begin
  inherited Create(AOwner);
  FPostPerformaceCounter := 0;
  FLastPostPerformaceTime := GetTimeTick;
  FPostCounterOfPerSec := 0;
end;

destructor TDataStoreService_PeerClientRecvTunnel_VirtualAuth.Destroy;
begin
  inherited Destroy;
end;

procedure TDataStoreService_PeerClientRecvTunnel_VirtualAuth.Progress;
var
  lastTime: TTimeTickValue;
begin
  lastTime := GetTimeTick;

  inherited Progress;

  if lastTime - FLastPostPerformaceTime > 1000 then
    begin
      try
        if FPostPerformaceCounter > 0 then
            FPostCounterOfPerSec := FPostPerformaceCounter / ((lastTime - FLastPostPerformaceTime) * 0.001)
        else
            FPostCounterOfPerSec := 0;
      except
          FPostCounterOfPerSec := 0;
      end;
      FLastPostPerformaceTime := lastTime;
      FPostPerformaceCounter := 0;
    end;
end;

function TDataStoreService_PeerClientRecvTunnel_VirtualAuth.SendTunnelDefine: TDataStoreService_PeerClientSendTunnel_VirtualAuth;
begin
  Result := SendTunnel as TDataStoreService_PeerClientSendTunnel_VirtualAuth;
end;

constructor TDataStoreService_PeerClientSendTunnel_VirtualAuth.Create(AOwner: TPeerIO);
begin
  inherited Create(AOwner);
end;

destructor TDataStoreService_PeerClientSendTunnel_VirtualAuth.Destroy;
begin
  inherited Destroy;
end;

function TDataStoreService_PeerClientSendTunnel_VirtualAuth.RecvTunnelDefine: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
begin
  Result := RecvTunnel as TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
end;

procedure TDataStoreService_VirtualAuth.CreateQuery(pipe: TZDBPipeline);
var
  pl: TTDataStoreService_DBPipeline;
begin
  pl := TTDataStoreService_DBPipeline(pipe);
end;

procedure TDataStoreService_VirtualAuth.QueryFragmentData(pipe: TZDBPipeline; FragmentSource: TMemoryStream64);
var
  pl: TTDataStoreService_DBPipeline;
  destStream: TMemoryStream64;
begin
  pl := TTDataStoreService_DBPipeline(pipe);
  if not pl.SyncToClient then
      exit;

  if not SendTunnel.Exists(pl.SendTunnel) then
      exit;

  destStream := TMemoryStream64.Create;
  FragmentSource.Position := 0;

  CompressStream(FragmentSource, destStream);

  SequEncrypt(destStream.Memory, destStream.Size, True, True);

  ClearBatchStream(pl.SendTunnel.Owner);
  PostBatchStream(pl.SendTunnel.Owner, destStream, True);
  Send_CompletedFragmentBigStream(pl);
  ClearBatchStream(pl.SendTunnel.Owner);
end;

procedure TDataStoreService_VirtualAuth.QueryDone(pipe: TZDBPipeline);
var
  pl: TTDataStoreService_DBPipeline;
begin
  pl := TTDataStoreService_DBPipeline(pipe);

  if not FSendTunnel.Exists(pl.SendTunnel) then
      exit;

  Send_CompletedQuery(pl);
end;

procedure TDataStoreService_VirtualAuth.StorePosTransform(const Data: Pointer; const TransformBuff: PZDBStorePosTransformArray);
var
  p: POnStorePosTransformTrigger_VirtualAuth;
  de: TDataFrameEngine;
begin
  if Data = nil then
      exit;
  p := POnStorePosTransformTrigger_VirtualAuth(Data);
  if (p^.BackcallPtr <> 0) and (FSendTunnel.Exists(p^.Client_SendTunnel_ID)) then
      Send_CompletedStorePosTransform(SendTunnel.ClientFromID[p^.Client_SendTunnel_ID], p^.BackcallPtr, TransformBuff);
  Dispose(p);
end;

procedure TDataStoreService_VirtualAuth.CreateDB(ActiveDB: TZDBStoreEngine);
begin
end;

procedure TDataStoreService_VirtualAuth.CloseDB(ActiveDB: TZDBStoreEngine);
begin
end;

procedure TDataStoreService_VirtualAuth.InsertData(Sender: TZDBStoreEngine; InsertPos: Int64; buff: TCoreClassStream; id: Cardinal; CompletePos: Int64);
begin
end;

procedure TDataStoreService_VirtualAuth.AddData(Sender: TZDBStoreEngine; buff: TCoreClassStream; id: Cardinal; CompletePos: Int64);
begin
end;

procedure TDataStoreService_VirtualAuth.ModifyData(Sender: TZDBStoreEngine; const StorePos: Int64; buff: TCoreClassStream);
begin
end;

procedure TDataStoreService_VirtualAuth.DeleteData(Sender: TZDBStoreEngine; const StorePos: Int64);
begin
end;

procedure TDataStoreService_VirtualAuth.DownloadQueryFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
begin
  Allowed := True;
end;

procedure TDataStoreService_VirtualAuth.DownloadQueryWithIDFilterMethod(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
begin
  try
      Allowed := qState.id = dPipe.UserVariant;
  except
      Allowed := False;
  end;
end;

procedure TDataStoreService_VirtualAuth.UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth);
var
  i: Integer;
  pl: TTDataStoreService_DBPipeline;
begin
  for i := 0 to FZDBLocal.QueryPipelineList.Count - 1 do
    begin
      pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryPipelineList[i]);
      if pl.RecvTunnel = UserDefineIO.Owner.UserDefine then
          pl.Stop;
    end;
  inherited UserOut(UserDefineIO);
end;

procedure TDataStoreService_VirtualAuth.Command_InitDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  inMem: Boolean;
  dbN: SystemString;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  inMem := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;
  if inMem then
      FZDBLocal.InitMemoryDB(dbN)
  else
      FZDBLocal.InitDB(dbN, False);
end;

procedure TDataStoreService_VirtualAuth.Command_CloseDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  CloseAndDeleted: Boolean;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  CloseAndDeleted := InData.Reader.ReadBool;

  if CloseAndDeleted then
      FZDBLocal.CloseAndDeleteDB(dbN)
  else
      FZDBLocal.CloseDB(dbN);
end;

procedure TDataStoreService_VirtualAuth.Command_CopyDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN, copy2N: SystemString;
  BackcallPtr: UInt64;
  p: POnStorePosTransformTrigger_VirtualAuth;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  copy2N := InData.Reader.ReadString;
  BackcallPtr := InData.Reader.ReadPointer;

  new(p);
  p^.Client_SendTunnel_ID := rt.SendTunnelID;
  p^.BackcallPtr := BackcallPtr;
  {$IFDEF FPC}
  FZDBLocal.CopyDB(dbN, copy2N, p, @StorePosTransform);
  {$ELSE FPC}
  FZDBLocal.CopyDB(dbN, copy2N, p, StorePosTransform);
  {$ENDIF FPC}
end;

procedure TDataStoreService_VirtualAuth.Command_CompressDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  BackcallPtr: UInt64;
  p: POnStorePosTransformTrigger_VirtualAuth;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  BackcallPtr := InData.Reader.ReadPointer;

  new(p);
  p^.Client_SendTunnel_ID := rt.SendTunnelID;
  p^.BackcallPtr := BackcallPtr;
  {$IFDEF FPC}
  FZDBLocal.CompressDB(dbN, p, @StorePosTransform);
  {$ELSE FPC}
  FZDBLocal.CompressDB(dbN, p, StorePosTransform);
  {$ENDIF FPC}
end;

procedure TDataStoreService_VirtualAuth.Command_ReplaceDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN, ReplaceN: SystemString;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  ReplaceN := InData.Reader.ReadString;
  FZDBLocal.ReplaceDB(dbN, ReplaceN);
end;

procedure TDataStoreService_VirtualAuth.Command_ResetData(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  FZDBLocal.ResetData(dbN);
end;

procedure TDataStoreService_VirtualAuth.Command_QueryDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  RegedQueryName: SystemString;
  SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean;
  dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double;
  MaxQueryResult: Int64;

  AutoDestoryOutputDB: Boolean;
  DelayDestoryTime: Double;
  pl: TTDataStoreService_DBPipeline;
  qc: TTDataStoreService_QueryCall;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  RegedQueryName := InData.Reader.ReadString;
  SyncToClient := InData.Reader.ReadBool;
  WriteResultToOutputDB := InData.Reader.ReadBool;
  inMem := InData.Reader.ReadBool;
  ReverseQuery := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;
  outDBN := InData.Reader.ReadString;
  fragmentReponseTime := InData.Reader.ReadDouble;
  MaxWait := InData.Reader.ReadDouble;
  MaxQueryResult := InData.Reader.ReadInt64;

  if not FZDBLocal.ExistsDB(dbN) then
      exit;

  qc := TTDataStoreService_QueryCall(FQueryCallPool[RegedQueryName]);

  if inMem then
      AutoDestoryOutputDB := True
  else
      AutoDestoryOutputDB := False;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryDB(WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN,
    AutoDestoryOutputDB, FPerQueryPipelineDelayFreeTime, fragmentReponseTime, MaxWait, 0, MaxQueryResult));
  pl.SendTunnel := rt.SendTunnelDefine;
  pl.RecvTunnel := rt;
  pl.BackcallPtr := InData.Reader.ReadPointer;
  pl.SyncToClient := SyncToClient;
  pl.RegistedQuery := RegedQueryName;
  pl.WriteFragmentBuffer := pl.SyncToClient;

  if InData.Reader.NotEnd then
      InData.Reader.ReadVariantList(pl.Values);

  if qc <> nil then
    begin
      pl.OnDataFilterMethod := qc.OnPipelineQuery;
      pl.OnDataDoneMethod := qc.OnPipelineQueryDone;
    end
  else
    begin
      {$IFDEF FPC}
      pl.OnDataFilterMethod := @DownloadQueryFilterMethod;
      {$ELSE}
      pl.OnDataFilterMethod := DownloadQueryFilterMethod;
      {$ENDIF}
    end;
  ClearBatchStream(rt.SendTunnelDefine.Owner);
end;

procedure TDataStoreService_VirtualAuth.Command_DownloadDB(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  ReverseQuery: Boolean;
  dbN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  ReverseQuery := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;

  if not FZDBLocal.ExistsDB(dbN) then
      exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryDB(False, True, ReverseQuery, dbN, '', True, FPerQueryPipelineDelayFreeTime, 0.5, 0, 0, 0));
  pl.SendTunnel := rt.SendTunnelDefine;
  pl.RecvTunnel := rt;
  pl.BackcallPtr := InData.Reader.ReadPointer;
  pl.SyncToClient := True;
  pl.WriteFragmentBuffer := pl.SyncToClient;
  //
  {$IFDEF FPC}
  pl.OnDataFilterMethod := @DownloadQueryFilterMethod;
  {$ELSE}
  pl.OnDataFilterMethod := DownloadQueryFilterMethod;
  {$ENDIF}
  ClearBatchStream(rt.SendTunnelDefine.Owner);
end;

procedure TDataStoreService_VirtualAuth.Command_DownloadDBWithID(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  ReverseQuery: Boolean;
  dbN: SystemString;
  downloadWithID: Cardinal;
  pl: TTDataStoreService_DBPipeline;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  ReverseQuery := InData.Reader.ReadBool;
  dbN := InData.Reader.ReadString;
  downloadWithID := InData.Reader.ReadCardinal;

  if not FZDBLocal.ExistsDB(dbN) then
      exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryDB(False, True, ReverseQuery, dbN, '', True, FPerQueryPipelineDelayFreeTime, 0.5, 0, 0, 0));
  pl.SendTunnel := rt.SendTunnelDefine;
  pl.RecvTunnel := rt;
  pl.BackcallPtr := InData.Reader.ReadPointer;
  pl.SyncToClient := True;
  pl.WriteFragmentBuffer := pl.SyncToClient;
  //
  // user download with ID
  pl.UserVariant := downloadWithID;
  //
  {$IFDEF FPC}
  pl.OnDataFilterMethod := @DownloadQueryWithIDFilterMethod;
  {$ELSE}
  pl.OnDataFilterMethod := DownloadQueryWithIDFilterMethod;
  {$ENDIF}
  ClearBatchStream(rt.SendTunnelDefine.Owner);
end;

procedure TDataStoreService_VirtualAuth.Command_RequestDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  StorePos: Int64;
  BackcallPtr: UInt64;
  m, cm: TMemoryStream64;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  StorePos := InData.Reader.ReadInt64;
  BackcallPtr := InData.Reader.ReadPointer;

  m := TMemoryStream64.Create;
  if not FZDBLocal.WriteDBItemToOneFragment(dbN, StorePos, m) then
    begin
      Sender.PrintParam('get Data Assemble Stream error: %s', dbN);
      disposeObject(m);
      exit;
    end;
  cm := TMemoryStream64.Create;
  m.Position := 0;
  CompressStream(m, cm);
  disposeObject(m);

  SequEncrypt(cm.Memory, cm.Size, True, True);

  ClearBatchStream(rt.SendTunnelDefine.Owner);
  PostBatchStream(rt.SendTunnelDefine.Owner, cm, True);
  Send_CompletedDownloadAssemble(rt.SendTunnelDefine.Owner, dbN, StorePos, BackcallPtr);
  ClearBatchStream(rt.SendTunnelDefine.Owner);
end;

procedure TDataStoreService_VirtualAuth.Command_RequestFastDownloadAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  StorePos: Int64;
  BackcallPtr: UInt64;
  m: TMemoryStream64;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  StorePos := InData.Reader.ReadInt64;
  BackcallPtr := InData.Reader.ReadPointer;

  m := TMemoryStream64.Create;
  if not FZDBLocal.WriteDBItemToOneFragment(dbN, StorePos, m) then
    begin
      Sender.PrintParam('get Data Assemble Stream error: %s', dbN);
      disposeObject(m);
      exit;
    end;

  ClearBatchStream(rt.SendTunnelDefine.Owner);
  PostBatchStream(rt.SendTunnelDefine.Owner, m, True);
  Send_CompletedFastDownloadAssemble(rt.SendTunnelDefine.Owner, dbN, StorePos, BackcallPtr);
  ClearBatchStream(rt.SendTunnelDefine.Owner);
end;

procedure TDataStoreService_VirtualAuth.Command_FastPostCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: TPascalString;
  itmID: Cardinal;
  StorePos: Int64;
  output: Pointer;
  outputSiz: NativeUInt;
  m64: TMemoryStream64;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;
  inc(rt.FPostPerformaceCounter);

  DecodeOneBuff(InData, DataSize, dbN, itmID, StorePos, output, outputSiz);
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(output, outputSiz);
  FZDBLocal.PostData(dbN, m64, itmID);
  disposeObject(m64);
end;

procedure TDataStoreService_VirtualAuth.Command_FastInsertCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: TPascalString;
  itmID: Cardinal;
  StorePos: Int64;
  output: Pointer;
  outputSiz: NativeUInt;
  m64: TMemoryStream64;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;
  inc(rt.FPostPerformaceCounter);

  DecodeOneBuff(InData, DataSize, dbN, itmID, StorePos, output, outputSiz);
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(output, outputSiz);
  FZDBLocal.InsertData(dbN, StorePos, m64, itmID);
  disposeObject(m64);
end;

procedure TDataStoreService_VirtualAuth.Command_FastModifyCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: TPascalString;
  itmID: Cardinal;
  StorePos: Int64;
  output: Pointer;
  outputSiz: NativeUInt;
  m64: TMemoryStream64;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;
  inc(rt.FPostPerformaceCounter);

  DecodeOneBuff(InData, DataSize, dbN, itmID, StorePos, output, outputSiz);
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(output, outputSiz);
  FZDBLocal.SetData(dbN, StorePos, m64);
  disposeObject(m64);
end;

procedure TDataStoreService_VirtualAuth.Command_CompletedPostAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  dID: Cardinal;
  p: PBigStreamBatchPostData;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  if rt.BigStreamBatchList.Count <= 0 then
      exit;

  dbN := InData.Reader.ReadString;
  dID := InData.Reader.ReadCardinal;

  p := rt.BigStreamBatchList.Last;
  SequEncrypt(p^.Source.Memory, p^.Source.Size, False, True);
  p^.DBStorePos := FZDBLocal.PostData(dbN, p^.Source, dID);
  inc(rt.FPostPerformaceCounter);
end;

procedure TDataStoreService_VirtualAuth.Command_CompletedInsertAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  dStorePos: Int64;
  dID: Cardinal;
  p: PBigStreamBatchPostData;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  if rt.BigStreamBatchList.Count <= 0 then
      exit;

  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  dID := InData.Reader.ReadCardinal;

  p := rt.BigStreamBatchList.Last;
  SequEncrypt(p^.Source.Memory, p^.Source.Size, False, True);
  p^.DBStorePos := FZDBLocal.InsertData(dbN, dStorePos, p^.Source, dID);
  inc(rt.FPostPerformaceCounter);
end;

procedure TDataStoreService_VirtualAuth.Command_CompletedModifyAssembleStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  dStorePos: Int64;
  p: PBigStreamBatchPostData;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  if rt.BigStreamBatchList.Count <= 0 then
      exit;

  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;

  p := rt.BigStreamBatchList.Last;
  SequEncrypt(p^.Source.Memory, p^.Source.Size, False, True);

  if FZDBLocal.SetData(dbN, dStorePos, p^.Source) then
    begin
      p^.DBStorePos := dStorePos;
    end
  else
    begin
    end;
  inc(rt.FPostPerformaceCounter);
end;

procedure TDataStoreService_VirtualAuth.Command_DeleteData(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  dbN: SystemString;
  dStorePos: Int64;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  FZDBLocal.DeleteData(dbN, dStorePos);
  inc(rt.FPostPerformaceCounter);
end;

procedure TDataStoreService_VirtualAuth.Command_GetDBList(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  lst: TCoreClassListForObj;
  i: Integer;
  db: TZDBStoreEngine;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  lst := TCoreClassListForObj.Create;
  FZDBLocal.GetDBList(lst);
  for i := 0 to lst.Count - 1 do
    begin
      db := TZDBStoreEngine(lst[i]);
      OutData.WriteString(db.name);
    end;
  disposeObject(lst);
end;

procedure TDataStoreService_VirtualAuth.Command_GetQueryList(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  i: Integer;
  pl: TTDataStoreService_DBPipeline;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;
  for i := 0 to FZDBLocal.QueryPipelineList.Count - 1 do
    begin
      pl := TTDataStoreService_DBPipeline(FZDBLocal.QueryPipelineList[i]);
      if (pl.RecvTunnel <> nil) and (pl.RecvTunnel.Owner = Sender) and
        (pl.Activted) and (pl.SourceDB <> nil) and (pl.OutputDB <> nil) then
          OutData.WriteString(pl.PipelineName);
    end;
end;

procedure TDataStoreService_VirtualAuth.Command_GetQueryState(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
  ps: TPipeState;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl = nil then
      exit;

  if not pl.Activted then
      exit;
  if pl.SourceDB = nil then
      exit;
  if pl.OutputDB = nil then
      exit;

  ps.Init;
  ps.WriteOutputDB := (pl.WriteResultToOutputDB);
  ps.Activted := (pl.Activted);
  ps.SyncToClient := (pl.SyncToClient);
  ps.MemoryMode := (pl.OutputDB.IsMemoryMode);
  ps.Paused := (pl.Paused);
  ps.DBCounter := (pl.SourceDB.Count);
  ps.QueryCounter := (pl.QueryCounter);
  ps.QueryResultCounter := (pl.QueryResultCounter);
  ps.MaxQueryCompare := (pl.MaxQueryCompare);
  ps.MaxQueryResult := (pl.MaxQueryResult);
  ps.QueryPerformanceOfPerSec := (pl.QueryCounterOfPerSec);
  ps.ConsumTime := (pl.QueryConsumTime);
  ps.MaxWaitTime := (pl.MaxWaitTime);
  ps.SourceDB := (pl.SourceDBName);
  ps.OutputDB := (pl.OutputDBName);
  ps.PipelineName := (pl.PipelineName);
  ps.RegistedQuery := (pl.RegistedQuery);
  ps.Encode(OutData);
  ps.Init;
end;

procedure TDataStoreService_VirtualAuth.Command_QueryStop(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl <> nil then
      pl.Stop;
end;

procedure TDataStoreService_VirtualAuth.Command_QueryPause(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl <> nil then
      pl.Pause;
end;

procedure TDataStoreService_VirtualAuth.Command_QueryPlay(Sender: TPeerIO; InData: TDataFrameEngine);
var
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  pipeN: SystemString;
  pl: TTDataStoreService_DBPipeline;
begin
  rt := GetDataStoreUserDefine(Sender);
  if not rt.LinkOk then
      exit;

  pipeN := InData.Reader.ReadString;
  if not FZDBLocal.ExistsPipeline(pipeN) then
      exit;

  pl := TTDataStoreService_DBPipeline(FZDBLocal.PipelineN[pipeN]);
  if pl <> nil then
      pl.Play;
end;

procedure TDataStoreService_VirtualAuth.Send_CompletedFragmentBigStream(pipe: TTDataStoreService_DBPipeline);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipe.SourceDBName);
  de.WriteString(pipe.OutputDBName);
  de.WriteString(pipe.PipelineName);
  de.WritePointer(pipe.BackcallPtr);
  pipe.SendTunnel.Owner.SendDirectStreamCmd('CompletedFragmentBigStream', de);
  disposeObject(de);
end;

procedure TDataStoreService_VirtualAuth.Send_CompletedQuery(pipe: TTDataStoreService_DBPipeline);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipe.SourceDBName);
  de.WriteString(pipe.OutputDBName);
  de.WriteString(pipe.PipelineName);
  de.WritePointer(pipe.BackcallPtr);
  de.WriteInt64(pipe.QueryResultCounter);
  pipe.SendTunnel.Owner.SendDirectStreamCmd('CompletedQuery', de);
  disposeObject(de);
  ClearBatchStream(pipe.SendTunnel.Owner);
end;

procedure TDataStoreService_VirtualAuth.Send_CompletedDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  de.WritePointer(BackcallPtr);
  ASendCli.SendDirectStreamCmd('CompletedDownloadAssemble', de);
  disposeObject(de);
  ClearBatchStream(ASendCli);
end;

procedure TDataStoreService_VirtualAuth.Send_CompletedFastDownloadAssemble(ASendCli: TPeerIO; dbN: SystemString; dStorePos: Int64; BackcallPtr: UInt64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  de.WritePointer(BackcallPtr);
  ASendCli.SendDirectStreamCmd('CompletedFastDownloadAssemble', de);
  disposeObject(de);
  ClearBatchStream(ASendCli);
end;

procedure TDataStoreService_VirtualAuth.Send_CompletedStorePosTransform(ASendCli: TPeerIO; const BackcallPtr: UInt64; const TransformBuff: PZDBStorePosTransformArray);
var
  de: TDataFrameEngine;
  i: Integer;
  arr: TDataFrameArrayInt64;
begin
  de := TDataFrameEngine.Create;
  de.WritePointer(BackcallPtr);

  arr := de.WriteArrayInt64;
  for i := 0 to length(TransformBuff^) - 1 do
      arr.Add(TransformBuff^[i].OriginPos);

  arr := de.WriteArrayInt64;
  for i := 0 to length(TransformBuff^) - 1 do
      arr.Add(TransformBuff^[i].NewPos);

  ASendCli.SendDirectStreamCmd('CompletedStorePosTransform', de);
  disposeObject(de);
end;

constructor TDataStoreService_VirtualAuth.Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkServer);
begin
  inherited Create(ARecvTunnel, ASendTunnel);
  FRecvTunnel.PeerClientUserDefineClass := TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
  FSendTunnel.PeerClientUserDefineClass := TDataStoreService_PeerClientSendTunnel_VirtualAuth;

  FZDBLocal := TZDBLocalManager.Create;
  FZDBLocal.PipelineClass := TTDataStoreService_DBPipeline;
  FZDBLocal.NotifyIntf := Self;

  FQueryCallPool := THashObjectList.Create(True);

  FPerQueryPipelineDelayFreeTime := 3.0;
end;

destructor TDataStoreService_VirtualAuth.Destroy;
begin
  disposeObject([FZDBLocal, FQueryCallPool]);
  inherited Destroy;
end;

procedure TDataStoreService_VirtualAuth.RegisterCommand;
begin
  inherited RegisterCommand;
  {$IFDEF FPC}
  FRecvTunnel.RegisterDirectStream('InitDB').OnExecute := @Command_InitDB;
  FRecvTunnel.RegisterDirectStream('CloseDB').OnExecute := @Command_CloseDB;

  FRecvTunnel.RegisterDirectStream('CopyDB').OnExecute := @Command_CopyDB;
  FRecvTunnel.RegisterDirectStream('CompressDB').OnExecute := @Command_CompressDB;
  FRecvTunnel.RegisterDirectStream('ReplaceDB').OnExecute := @Command_ReplaceDB;
  FRecvTunnel.RegisterDirectStream('ResetData').OnExecute := @Command_ResetData;

  FRecvTunnel.RegisterDirectStream('QueryDB').OnExecute := @Command_QueryDB;
  FRecvTunnel.RegisterDirectStream('DownloadDB').OnExecute := @Command_DownloadDB;
  FRecvTunnel.RegisterDirectStream('DownloadDBWithID').OnExecute := @Command_DownloadDBWithID;
  FRecvTunnel.RegisterDirectStream('RequestDownloadAssembleStream').OnExecute := @Command_RequestDownloadAssembleStream;
  FRecvTunnel.RegisterDirectStream('RequestFastDownloadAssembleStream').OnExecute := @Command_RequestFastDownloadAssembleStream;

  FRecvTunnel.RegisterCompleteBuffer('FastPostCompleteBuffer').OnExecute := @Command_FastPostCompleteBuffer;
  FRecvTunnel.RegisterCompleteBuffer('FastInsertCompleteBuffer').OnExecute := @Command_FastInsertCompleteBuffer;
  FRecvTunnel.RegisterCompleteBuffer('FastModifyCompleteBuffer').OnExecute := @Command_FastModifyCompleteBuffer;

  FRecvTunnel.RegisterDirectStream('CompletedPostAssembleStream').OnExecute := @Command_CompletedPostAssembleStream;
  FRecvTunnel.RegisterDirectStream('CompletedInsertAssembleStream').OnExecute := @Command_CompletedInsertAssembleStream;
  FRecvTunnel.RegisterDirectStream('CompletedModifyAssembleStream').OnExecute := @Command_CompletedModifyAssembleStream;
  FRecvTunnel.RegisterDirectStream('DeleteData').OnExecute := @Command_DeleteData;

  FRecvTunnel.RegisterStream('GetDBList').OnExecute := @Command_GetDBList;
  FRecvTunnel.RegisterStream('GetQueryList').OnExecute := @Command_GetQueryList;
  FRecvTunnel.RegisterStream('GetQueryState').OnExecute := @Command_GetQueryState;
  FRecvTunnel.RegisterDirectStream('QueryStop').OnExecute := @Command_QueryStop;
  FRecvTunnel.RegisterDirectStream('QueryPause').OnExecute := @Command_QueryPause;
  FRecvTunnel.RegisterDirectStream('QueryPlay').OnExecute := @Command_QueryPlay;
  {$ELSE}
  FRecvTunnel.RegisterDirectStream('InitDB').OnExecute := Command_InitDB;
  FRecvTunnel.RegisterDirectStream('CloseDB').OnExecute := Command_CloseDB;

  FRecvTunnel.RegisterDirectStream('CopyDB').OnExecute := Command_CopyDB;
  FRecvTunnel.RegisterDirectStream('CompressDB').OnExecute := Command_CompressDB;
  FRecvTunnel.RegisterDirectStream('ReplaceDB').OnExecute := Command_ReplaceDB;
  FRecvTunnel.RegisterDirectStream('ResetData').OnExecute := Command_ResetData;

  FRecvTunnel.RegisterDirectStream('QueryDB').OnExecute := Command_QueryDB;
  FRecvTunnel.RegisterDirectStream('DownloadDB').OnExecute := Command_DownloadDB;
  FRecvTunnel.RegisterDirectStream('DownloadDBWithID').OnExecute := Command_DownloadDBWithID;
  FRecvTunnel.RegisterDirectStream('RequestDownloadAssembleStream').OnExecute := Command_RequestDownloadAssembleStream;
  FRecvTunnel.RegisterDirectStream('RequestFastDownloadAssembleStream').OnExecute := Command_RequestFastDownloadAssembleStream;

  FRecvTunnel.RegisterCompleteBuffer('FastPostCompleteBuffer').OnExecute := Command_FastPostCompleteBuffer;
  FRecvTunnel.RegisterCompleteBuffer('FastInsertCompleteBuffer').OnExecute := Command_FastInsertCompleteBuffer;
  FRecvTunnel.RegisterCompleteBuffer('FastModifyCompleteBuffer').OnExecute := Command_FastModifyCompleteBuffer;

  FRecvTunnel.RegisterDirectStream('CompletedPostAssembleStream').OnExecute := Command_CompletedPostAssembleStream;
  FRecvTunnel.RegisterDirectStream('CompletedInsertAssembleStream').OnExecute := Command_CompletedInsertAssembleStream;
  FRecvTunnel.RegisterDirectStream('CompletedModifyAssembleStream').OnExecute := Command_CompletedModifyAssembleStream;
  FRecvTunnel.RegisterDirectStream('DeleteData').OnExecute := Command_DeleteData;

  FRecvTunnel.RegisterStream('GetDBList').OnExecute := Command_GetDBList;
  FRecvTunnel.RegisterStream('GetQueryList').OnExecute := Command_GetQueryList;
  FRecvTunnel.RegisterStream('GetQueryState').OnExecute := Command_GetQueryState;
  FRecvTunnel.RegisterDirectStream('QueryStop').OnExecute := Command_QueryStop;
  FRecvTunnel.RegisterDirectStream('QueryPause').OnExecute := Command_QueryPause;
  FRecvTunnel.RegisterDirectStream('QueryPlay').OnExecute := Command_QueryPlay;
  {$ENDIF}
end;

procedure TDataStoreService_VirtualAuth.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
  FRecvTunnel.DeleteRegistedCMD('InitDB');
  FRecvTunnel.DeleteRegistedCMD('CloseDB');

  FRecvTunnel.DeleteRegistedCMD('CopyDB');
  FRecvTunnel.DeleteRegistedCMD('CompressDB');
  FRecvTunnel.DeleteRegistedCMD('ReplaceDB');
  FRecvTunnel.DeleteRegistedCMD('ResetData');

  FRecvTunnel.DeleteRegistedCMD('QueryDB');
  FRecvTunnel.DeleteRegistedCMD('DownloadDB');
  FRecvTunnel.DeleteRegistedCMD('RequestDownloadAssembleStream');

  FRecvTunnel.DeleteRegistedCMD('FastPostCompleteBuffer');
  FRecvTunnel.DeleteRegistedCMD('FastInsertCompleteBuffer');
  FRecvTunnel.DeleteRegistedCMD('FastModifyCompleteBuffer');

  FRecvTunnel.DeleteRegistedCMD('CompletedPostAssembleStream');
  FRecvTunnel.DeleteRegistedCMD('CompletedInsertAssembleStream');
  FRecvTunnel.DeleteRegistedCMD('CompletedModifyAssembleStream');
  FRecvTunnel.DeleteRegistedCMD('DeleteData');

  FRecvTunnel.DeleteRegistedCMD('GetDBList');
  FRecvTunnel.DeleteRegistedCMD('GetQueryList');
  FRecvTunnel.DeleteRegistedCMD('GetQueryState');
  FRecvTunnel.DeleteRegistedCMD('QueryStop');
  FRecvTunnel.DeleteRegistedCMD('QueryPause');
  FRecvTunnel.DeleteRegistedCMD('QueryPlay');
end;

procedure TDataStoreService_VirtualAuth.Progress;
begin
  inherited Progress;
  FZDBLocal.Progress;
end;

procedure TDataStoreService_VirtualAuth.CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  inherited CadencerProgress(Sender, deltaTime, newTime);
end;

function TDataStoreService_VirtualAuth.GetDataStoreUserDefine(RecvCli: TPeerIO): TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
begin
  Result := RecvCli.UserDefine as TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
end;

function TDataStoreService_VirtualAuth.RegisterQueryCall(cName: SystemString): TTDataStoreService_QueryCall;
begin
  if FQueryCallPool.Exists(cName) then
      RaiseInfo('Query call already registed:%s', [cName]);

  Result := TTDataStoreService_QueryCall.Create;
  FQueryCallPool[cName] := Result;
end;

procedure TDataStoreService_VirtualAuth.UnRegisterQueryCall(cName: SystemString);
begin
  if not FQueryCallPool.Exists(cName) then
      RaiseInfo('Query call not registed:%s', [cName]);

  FQueryCallPool.Delete(cName);
end;

function TDataStoreService_VirtualAuth.GetRegistedQueryCall(cName: SystemString): TTDataStoreService_QueryCall;
begin
  Result := TTDataStoreService_QueryCall(FQueryCallPool[cName]);
end;

function TDataStoreService_VirtualAuth.PostCounterOfPerSec: Double;
var
  IDPool: TClientIDPool;
  pcid: Cardinal;
  rt: TDataStoreService_PeerClientRecvTunnel_VirtualAuth;
begin
  Result := 0;
  FRecvTunnel.GetClientIDPool(IDPool);
  for pcid in IDPool do
    begin
      rt := GetDataStoreUserDefine(FRecvTunnel.ClientFromID[pcid]);
      Result := Result + rt.FPostCounterOfPerSec;
    end;
end;

procedure TDataStoreClient_VirtualAuth.Command_CompletedFragmentBigStream(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN, outN, pipeN: SystemString;
  BackcallPtr: PDataStoreClientQueryNotify;
  m: TMemoryStream64;
begin
  dbN := InData.Reader.ReadString;
  outN := InData.Reader.ReadString;
  pipeN := InData.Reader.ReadString;
  BackcallPtr := PDataStoreClientQueryNotify(InData.Reader.ReadPointer);

  m := TMemoryStream64.Create;

  if Sender.UserDefine.BigStreamBatchList.Count > 0 then
    begin
      Sender.UserDefine.BigStreamBatchList.Last^.Source.Position := 0;
      SequEncrypt(Sender.UserDefine.BigStreamBatchList.Last^.Source.Memory, Sender.UserDefine.BigStreamBatchList.Last^.Source.Size, False, True);
      Sender.UserDefine.BigStreamBatchList.Last^.Source.Position := 0;
      DecompressStream(Sender.UserDefine.BigStreamBatchList.Last^.Source, m);
      Sender.UserDefine.BigStreamBatchList.DeleteLast;
    end;

  if (BackcallPtr <> nil) and (m.Size > 0) then
    begin
      try
        m.Position := 0;
        if Assigned(BackcallPtr^.OnUserQueryCall) then
          begin
            FillFragmentSource(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, pipeN, m, BackcallPtr^.OnUserQueryCall);
            m.Position := 0;
          end;
        if Assigned(BackcallPtr^.OnUserQueryMethod) then
          begin
            FillFragmentSource(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, pipeN, m, BackcallPtr^.OnUserQueryMethod);
            m.Position := 0;
          end;
        {$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnUserQueryProc) then
          begin
            FillFragmentSource(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, pipeN, m, BackcallPtr^.OnUserQueryProc);
            m.Position := 0;
          end;
        {$ENDIF}
        //
        if Assigned(BackcallPtr^.OnQueryCall) then
          begin
            FillFragmentSource(dbN, pipeN, m, BackcallPtr^.OnQueryCall);
            m.Position := 0;
          end;
        if Assigned(BackcallPtr^.OnQueryMethod) then
          begin
            FillFragmentSource(dbN, pipeN, m, BackcallPtr^.OnQueryMethod);
            m.Position := 0;
          end;
        {$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnQueryProc) then
          begin
            FillFragmentSource(dbN, pipeN, m, BackcallPtr^.OnQueryProc);
            m.Position := 0;
          end;
        {$ENDIF}
      except
      end;
    end;

  disposeObject(m);
end;

procedure TDataStoreClient_VirtualAuth.Command_CompletedQuery(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN, outN, pipeN: SystemString;
  BackcallPtr: PDataStoreClientQueryNotify;
  TotalResultCount: Int64;
begin
  dbN := InData.Reader.ReadString;
  outN := InData.Reader.ReadString;
  pipeN := InData.Reader.ReadString;
  BackcallPtr := PDataStoreClientQueryNotify(InData.Reader.ReadPointer);
  TotalResultCount := InData.Reader.ReadInt64;

  if BackcallPtr <> nil then
    begin
      try
        if Assigned(BackcallPtr^.OnUserDoneCall) then
            BackcallPtr^.OnUserDoneCall(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, outN, pipeN, TotalResultCount);
        if Assigned(BackcallPtr^.OnUserDoneMethod) then
            BackcallPtr^.OnUserDoneMethod(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, outN, pipeN, TotalResultCount);
        {$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnUserDoneProc) then
            BackcallPtr^.OnUserDoneProc(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, outN, pipeN, TotalResultCount);
        {$ENDIF}
        //
        if Assigned(BackcallPtr^.OnDoneCall) then
            BackcallPtr^.OnDoneCall(dbN, outN, pipeN, TotalResultCount);
        if Assigned(BackcallPtr^.OnDoneMethod) then
            BackcallPtr^.OnDoneMethod(dbN, outN, pipeN, TotalResultCount);
        {$IFNDEF FPC}
        if Assigned(BackcallPtr^.OnDoneProc) then
            BackcallPtr^.OnDoneProc(dbN, outN, pipeN, TotalResultCount);
        {$ENDIF}
      except
      end;
      Dispose(BackcallPtr);
    end;
  Sender.UserDefine.BigStreamBatchList.Clear;
end;

procedure TDataStoreClient_VirtualAuth.Command_CompletedDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN: SystemString;
  dStorePos: Int64;
  BackcallPtr: PDataStoreClientDownloadNotify;
  m, cm: TMemoryStream64;
begin
  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  BackcallPtr := PDataStoreClientDownloadNotify(InData.Reader.ReadPointer);

  if Sender.UserDefine.BigStreamBatchList.Count > 0 then
      m := Sender.UserDefine.BigStreamBatchList.Last^.Source
  else
      m := nil;

  if BackcallPtr <> nil then
    begin
      if m <> nil then
        begin
          cm := TMemoryStream64.Create;
          SequEncrypt(m.Memory, m.Size, False, True);
          DecompressStream(m, cm);
          Sender.UserDefine.BigStreamBatchList.DeleteLast;

          try
            cm.Position := 0;
            if Assigned(BackcallPtr^.OnUserDoneCall) then
              begin
                BackcallPtr^.OnUserDoneCall(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, cm);
                cm.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnUserDoneMethod) then
              begin
                BackcallPtr^.OnUserDoneMethod(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, cm);
                cm.Position := 0;
              end;
            {$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnUserDoneProc) then
              begin
                BackcallPtr^.OnUserDoneProc(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, cm);
                cm.Position := 0;
              end;
            {$ENDIF}
            //
            if Assigned(BackcallPtr^.OnDoneCall) then
              begin
                BackcallPtr^.OnDoneCall(dbN, dStorePos, cm);
                cm.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnDoneMethod) then
              begin
                BackcallPtr^.OnDoneMethod(dbN, dStorePos, cm);
                cm.Position := 0;
              end;
            {$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnDoneProc) then
              begin
                BackcallPtr^.OnDoneProc(dbN, dStorePos, cm);
                cm.Position := 0;
              end;
            {$ENDIF}
            disposeObject(cm);
          except
          end;
        end;
      Dispose(BackcallPtr);
    end;
end;

procedure TDataStoreClient_VirtualAuth.Command_CompletedFastDownloadAssemble(Sender: TPeerIO; InData: TDataFrameEngine);
var
  dbN: SystemString;
  dStorePos: Int64;
  BackcallPtr: PDataStoreClientDownloadNotify;
  m: TMemoryStream64;
begin
  dbN := InData.Reader.ReadString;
  dStorePos := InData.Reader.ReadInt64;
  BackcallPtr := PDataStoreClientDownloadNotify(InData.Reader.ReadPointer);

  if Sender.UserDefine.BigStreamBatchList.Count > 0 then
      m := Sender.UserDefine.BigStreamBatchList.Last^.Source
  else
      m := nil;

  if BackcallPtr <> nil then
    begin
      if m <> nil then
        begin
          try
            m.Position := 0;
            if Assigned(BackcallPtr^.OnUserDoneCall) then
              begin
                BackcallPtr^.OnUserDoneCall(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, m);
                m.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnUserDoneMethod) then
              begin
                BackcallPtr^.OnUserDoneMethod(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, m);
                m.Position := 0;
              end;
            {$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnUserDoneProc) then
              begin
                BackcallPtr^.OnUserDoneProc(BackcallPtr^.UserPointer, BackcallPtr^.UserObject, BackcallPtr^.UserVariant, dbN, dStorePos, m);
                m.Position := 0;
              end;
            {$ENDIF}
            //
            if Assigned(BackcallPtr^.OnDoneCall) then
              begin
                BackcallPtr^.OnDoneCall(dbN, dStorePos, m);
                m.Position := 0;
              end;
            if Assigned(BackcallPtr^.OnDoneMethod) then
              begin
                BackcallPtr^.OnDoneMethod(dbN, dStorePos, m);
                m.Position := 0;
              end;
            {$IFNDEF FPC}
            if Assigned(BackcallPtr^.OnDoneProc) then
              begin
                BackcallPtr^.OnDoneProc(dbN, dStorePos, m);
                m.Position := 0;
              end;
            {$ENDIF}
          except
          end;
          Sender.UserDefine.BigStreamBatchList.DeleteLast;
        end;
      Dispose(BackcallPtr);
    end;
end;

procedure TDataStoreClient_VirtualAuth.Command_CompletedStorePosTransform(Sender: TPeerIO; InData: TDataFrameEngine);
var
  BackcallPtr: PStorePosTransformNotify;
  arr: TDataFrameArrayInt64;
  i: Integer;
  TransformBuff: TZDBStorePosTransformArray;
begin
  BackcallPtr := PStorePosTransformNotify(InData.Reader.ReadPointer);

  arr := InData.Reader.ReadArrayInt64;
  SetLength(TransformBuff, arr.Count);
  for i := 0 to arr.Count - 1 do
      TransformBuff[i].OriginPos := arr[i];

  arr := InData.Reader.ReadArrayInt64;
  for i := 0 to arr.Count - 1 do
      TransformBuff[i].NewPos := arr[i];

  if BackcallPtr <> nil then
    begin
      if Assigned(BackcallPtr^.OnDoneCall) then
          BackcallPtr^.OnDoneCall(@TransformBuff);
      if Assigned(BackcallPtr^.OnDoneMethod) then
          BackcallPtr^.OnDoneMethod(@TransformBuff);
      {$IFNDEF FPC}
      if Assigned(BackcallPtr^.OnDoneProc) then
          BackcallPtr^.OnDoneProc(@TransformBuff);
      {$ENDIF FPC}
    end;

  SetLength(TransformBuff, 0);
  Dispose(BackcallPtr);
end;

constructor TDataStoreClient_VirtualAuth.Create(ARecvTunnel, ASendTunnel: TCommunicationFrameworkClient);
begin
  inherited Create(ARecvTunnel, ASendTunnel);
end;

destructor TDataStoreClient_VirtualAuth.Destroy;
begin
  inherited Destroy;
end;

procedure TDataStoreClient_VirtualAuth.RegisterCommand;
begin
  inherited RegisterCommand;
  {$IFDEF FPC}
  FRecvTunnel.RegisterDirectStream('CompletedFragmentBigStream').OnExecute := @Command_CompletedFragmentBigStream;
  FRecvTunnel.RegisterDirectStream('CompletedQuery').OnExecute := @Command_CompletedQuery;
  FRecvTunnel.RegisterDirectStream('CompletedDownloadAssemble').OnExecute := @Command_CompletedDownloadAssemble;
  FRecvTunnel.RegisterDirectStream('CompletedFastDownloadAssemble').OnExecute := @Command_CompletedFastDownloadAssemble;
  FRecvTunnel.RegisterDirectStream('CompletedStorePosTransform').OnExecute := @Command_CompletedStorePosTransform;
  {$ELSE}
  FRecvTunnel.RegisterDirectStream('CompletedFragmentBigStream').OnExecute := Command_CompletedFragmentBigStream;
  FRecvTunnel.RegisterDirectStream('CompletedQuery').OnExecute := Command_CompletedQuery;
  FRecvTunnel.RegisterDirectStream('CompletedDownloadAssemble').OnExecute := Command_CompletedDownloadAssemble;
  FRecvTunnel.RegisterDirectStream('CompletedFastDownloadAssemble').OnExecute := Command_CompletedFastDownloadAssemble;
  FRecvTunnel.RegisterDirectStream('CompletedStorePosTransform').OnExecute := Command_CompletedStorePosTransform;
  {$ENDIF}
end;

procedure TDataStoreClient_VirtualAuth.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
  FRecvTunnel.DeleteRegistedCMD('CompletedFragmentBigStream');
  FRecvTunnel.DeleteRegistedCMD('CompletedQuery');
  FRecvTunnel.DeleteRegistedCMD('CompletedDownloadAssemble');
  FRecvTunnel.DeleteRegistedCMD('CompletedFastDownloadAssemble');
  FRecvTunnel.DeleteRegistedCMD('CompletedStorePosTransform');
end;

procedure TDataStoreClient_VirtualAuth.Progress;
begin
  inherited Progress;
end;

procedure TDataStoreClient_VirtualAuth.InitDB(inMem: Boolean; dbN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteBool(inMem);
  de.WriteString(dbN);

  SendTunnel.SendDirectStreamCmd('InitDB', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.CloseDB(dbN: SystemString; CloseAndDeleted: Boolean);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteBool(CloseAndDeleted);
  SendTunnel.SendDirectStreamCmd('CloseDB', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.CopyDB(dbN, copyToN: SystemString);
begin
  CopyDB(dbN, copyToN, nil);
end;

procedure TDataStoreClient_VirtualAuth.CopyDB(dbN, copyToN: SystemString; const BackcallPtr: PStorePosTransformNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteString(copyToN);
  de.WritePointer(BackcallPtr);
  SendTunnel.SendDirectStreamCmd('CopyDB', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.CopyDB_C(dbN, copyToN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;
  CopyDB(dbN, copyToN, p);
end;

procedure TDataStoreClient_VirtualAuth.CopyDB_M(dbN, copyToN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;
  CopyDB(dbN, copyToN, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.CopyDB_P(dbN, copyToN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;
  CopyDB(dbN, copyToN, p);
end;
{$ENDIF FPC}


procedure TDataStoreClient_VirtualAuth.CompressDB(dbN: SystemString);
begin
  CompressDB(dbN, nil);
end;

procedure TDataStoreClient_VirtualAuth.CompressDB(dbN: SystemString; const BackcallPtr: PStorePosTransformNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WritePointer(BackcallPtr);
  SendTunnel.SendDirectStreamCmd('CompressDB', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.CompressDB_C(dbN: SystemString; const OnDoneCall: TStorePosTransformNotifyCall);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;
  CompressDB(dbN, p);
end;

procedure TDataStoreClient_VirtualAuth.CompressDB_M(dbN: SystemString; const OnDoneMethod: TStorePosTransformNotifyMethod);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;
  CompressDB(dbN, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.CompressDB_P(dbN: SystemString; const OnDoneProc: TStorePosTransformNotifyProc);
var
  p: PStorePosTransformNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;
  CompressDB(dbN, p);
end;
{$ENDIF FPC}


procedure TDataStoreClient_VirtualAuth.ReplaceDB(dbN, ReplaceN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteString(ReplaceN);
  SendTunnel.SendDirectStreamCmd('ReplaceDB', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.ResetData(dbN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  SendTunnel.SendDirectStreamCmd('ResetData', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.QuietQueryDB(RegistedQueryName: SystemString; ReverseQuery: Boolean; dbN, outDBN: SystemString; MaxWait: Double; MaxQueryResult: Int64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(RegistedQueryName);
  de.WriteBool(False); // sync to client
  de.WriteBool(True);  // write output db
  de.WriteBool(False); // in memory
  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WriteString(outDBN);
  de.WriteDouble(0.1); // fragmentReponseTime
  de.WriteDouble(MaxWait);
  de.WriteInt64(MaxQueryResult);
  de.WritePointer(0); // backcall address

  SendTunnel.SendDirectStreamCmd('QueryDB', de);

  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64; BackcallPtr: PDataStoreClientQueryNotify; RemoteParams: THashVariantList);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(RegistedQueryName);
  de.WriteBool(SyncToClient); // sync to client
  de.WriteBool(WriteResultToOutputDB);
  de.WriteBool(inMem);
  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WriteString(outDBN);
  de.WriteDouble(fragmentReponseTime);
  de.WriteDouble(MaxWait);
  de.WriteInt64(MaxQueryResult);
  de.WritePointer(BackcallPtr);
  if RemoteParams <> nil then
      de.WriteVariantList(RemoteParams);

  SendTunnel.SendDirectStreamCmd('QueryDB', de);

  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList;                                           // service ref remote parameter
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnQueryCall: TUserFillQueryDataCall; OnDoneCall: TUserQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserQueryCall := OnQueryCall;
  p^.OnUserDoneCall := OnDoneCall;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList;                                           // service ref remote parameter
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnQueryMethod: TUserFillQueryDataMethod; OnDoneMethod: TUserQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserQueryMethod := OnQueryMethod;
  p^.OnUserDoneMethod := OnDoneMethod;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery: Boolean; dbN, outDBN: SystemString;
  fragmentReponseTime, MaxWait: Double; MaxQueryResult: Int64;
  RemoteParams: THashVariantList;                                           // service ref remote parameter
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnQueryProc: TUserFillQueryDataProc; OnDoneProc: TUserQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserQueryProc := OnQueryProc;
  p^.OnUserDoneProc := OnDoneProc;
  QueryDB(RegistedQueryName, SyncToClient, WriteResultToOutputDB, inMem, ReverseQuery, dbN, outDBN, fragmentReponseTime, MaxWait, MaxQueryResult, p, RemoteParams);
end;

{$ENDIF}


procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  QueryDB(RegistedQueryName, True, False, True, False, dbN, 'Memory', 0.5, 0, 0, p, RemoteParams);
end;

procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  QueryDB(RegistedQueryName, True, False, True, False, dbN, 'Memory', 0.5, 0, 0, p, RemoteParams);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.QueryDB(RegistedQueryName: SystemString; dbN: SystemString; RemoteParams: THashVariantList; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  QueryDB(RegistedQueryName, True, False, True, False, dbN, 'Memory', 0.5, 0, 0, p, RemoteParams);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.DownloadDB(ReverseQuery: Boolean; dbN: SystemString; BackcallPtr: PDataStoreClientQueryNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd('DownloadDB', de);

  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.DownloadDB(ReverseQuery: Boolean; dbN: SystemString; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  DownloadDB(ReverseQuery, dbN, p);
end;

procedure TDataStoreClient_VirtualAuth.DownloadDB(ReverseQuery: Boolean; dbN: SystemString; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  DownloadDB(ReverseQuery, dbN, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.DownloadDB(ReverseQuery: Boolean; dbN: SystemString; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  DownloadDB(ReverseQuery, dbN, p);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; BackcallPtr: PDataStoreClientQueryNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteBool(ReverseQuery);
  de.WriteString(dbN);
  de.WriteCardinal(db_ID);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd('DownloadDBWithID', de);

  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryCall: TFillQueryDataCall; OnDoneCall: TQueryDoneNotifyCall);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryCall := OnQueryCall;
  p^.OnDoneCall := OnDoneCall;
  DownloadDBWithID(ReverseQuery, dbN, db_ID, p);
end;

procedure TDataStoreClient_VirtualAuth.DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryMethod: TFillQueryDataMethod; OnDoneMethod: TQueryDoneNotifyMethod);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryMethod := OnQueryMethod;
  p^.OnDoneMethod := OnDoneMethod;
  DownloadDBWithID(ReverseQuery, dbN, db_ID, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.DownloadDBWithID(ReverseQuery: Boolean; dbN: SystemString; db_ID: Cardinal; OnQueryProc: TFillQueryDataProc; OnDoneProc: TQueryDoneNotifyProc);
var
  p: PDataStoreClientQueryNotify;
begin
  new(p);
  p^.Init;
  p^.OnQueryProc := OnQueryProc;
  p^.OnDoneProc := OnDoneProc;
  DownloadDBWithID(ReverseQuery, dbN, db_ID, p);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.BeginAssembleStream;
begin
  ClearBatchStream;
end;

procedure TDataStoreClient_VirtualAuth.RequestDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(dbN);
  de.WriteInt64(StorePos);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd('RequestDownloadAssembleStream', de);

  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.DownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient_VirtualAuth.DownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.DownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.DownloadAssembleStream(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneCall: TUserDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneCall := OnDoneCall;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient_VirtualAuth.DownloadAssembleStream(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneMethod: TUserDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneMethod := OnDoneMethod;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.DownloadAssembleStream(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneProc: TUserDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneProc := OnDoneProc;

  RequestDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.RequestFastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; BackcallPtr: PDataStoreClientDownloadNotify);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  de.WriteString(dbN);
  de.WriteInt64(StorePos);
  de.WritePointer(BackcallPtr);

  SendTunnel.SendDirectStreamCmd('RequestFastDownloadAssembleStream', de);

  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneCall: TDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneCall := OnDoneCall;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient_VirtualAuth.FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneMethod: TDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneMethod := OnDoneMethod;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64; OnDoneProc: TDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.OnDoneProc := OnDoneProc;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneCall: TUserDownloadDoneNotifyCall);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneCall := OnDoneCall;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

procedure TDataStoreClient_VirtualAuth.FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneMethod: TUserDownloadDoneNotifyMethod);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneMethod := OnDoneMethod;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.FastDownloadAssembleStream(dbN: SystemString; StorePos: Int64;
  UserPointer: Pointer; UserObject: TCoreClassObject; UserVariant: Variant; // local event parameter
  OnDoneProc: TUserDownloadDoneNotifyProc);
var
  p: PDataStoreClientDownloadNotify;
begin
  new(p);
  p^.Init;
  p^.UserPointer := UserPointer;
  p^.UserObject := UserObject;
  p^.UserVariant := UserVariant;
  p^.OnUserDoneProc := OnDoneProc;

  RequestFastDownloadAssembleStream(dbN, StorePos, p);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.PostAssembleStream(dbN: SystemString; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  de: TDataFrameEngine;
begin
  SequEncrypt(Stream.Memory, Stream.Size, True, True);
  PostBatchStream(Stream, DoneTimeFree);

  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteCardinal(dID);
  SendTunnel.SendDirectStreamCmd('CompletedPostAssembleStream', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.PostAssembleStreamCopy(dbN: SystemString; Stream: TCoreClassStream; dID: Cardinal);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  Stream.Position := 0;
  m.CopyFrom(Stream, Stream.Size);
  m.Position := 0;
  PostAssembleStream(dbN, m, dID, True);
end;

procedure TDataStoreClient_VirtualAuth.PostAssembleStream(dbN: SystemString; DataSource: TDataFrameEngine);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.EncodeTo(m, True);
  PostAssembleStream(dbN, m, c_DF, True);
end;

procedure TDataStoreClient_VirtualAuth.PostAssembleStream(dbN: SystemString; DataSource: THashVariantList);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  PostAssembleStream(dbN, m, c_VL, True);
end;

procedure TDataStoreClient_VirtualAuth.PostAssembleStream(dbN: SystemString; DataSource: TSectionTextData);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  PostAssembleStream(dbN, m, c_TE, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.PostAssembleStream(dbN: SystemString; DataSource: TJsonObject);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  PostAssembleStream(dbN, m, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.PostAssembleStream(dbN: SystemString; DataSource: TPascalString);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, m);
  PostAssembleStream(dbN, m, c_PascalString, True);
end;

procedure TDataStoreClient_VirtualAuth.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  de: TDataFrameEngine;
begin
  SequEncrypt(Stream.Memory, Stream.Size, True, True);
  PostBatchStream(Stream, DoneTimeFree);

  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  de.WriteCardinal(dID);
  SendTunnel.SendDirectStreamCmd('CompletedInsertAssembleStream', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.InsertAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream; dID: Cardinal);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  Stream.Position := 0;
  m.CopyFrom(Stream, Stream.Size);
  m.Position := 0;
  InsertAssembleStream(dbN, dStorePos, m, dID, True);
end;

procedure TDataStoreClient_VirtualAuth.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.EncodeTo(m, True);
  InsertAssembleStream(dbN, dStorePos, m, c_DF, True);
end;

procedure TDataStoreClient_VirtualAuth.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  InsertAssembleStream(dbN, dStorePos, m, c_VL, True);
end;

procedure TDataStoreClient_VirtualAuth.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  InsertAssembleStream(dbN, dStorePos, m, c_TE, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m, False, TEncoding.UTF8, True);
  InsertAssembleStream(dbN, dStorePos, m, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.InsertAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, m);
  InsertAssembleStream(dbN, dStorePos, m, c_PascalString, True);
end;

procedure TDataStoreClient_VirtualAuth.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; DoneTimeFree: Boolean);
var
  de: TDataFrameEngine;
begin
  SequEncrypt(Stream.Memory, Stream.Size, True, True);

  PostBatchStream(Stream, DoneTimeFree);

  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  SendTunnel.SendDirectStreamCmd('CompletedModifyAssembleStream', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.ModifyAssembleStreamCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  Stream.Position := 0;
  m.CopyFrom(Stream, Stream.Size);
  m.Position := 0;
  ModifyAssembleStream(dbN, dStorePos, m, True);
end;

procedure TDataStoreClient_VirtualAuth.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.EncodeTo(m, True);
  ModifyAssembleStream(dbN, dStorePos, m, True);
end;

procedure TDataStoreClient_VirtualAuth.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  ModifyAssembleStream(dbN, dStorePos, m, True);
end;

procedure TDataStoreClient_VirtualAuth.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  ModifyAssembleStream(dbN, dStorePos, m, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m, False, TEncoding.UTF8, True);
  ModifyAssembleStream(dbN, dStorePos, m, True);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.ModifyAssembleStream(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, m);
  ModifyAssembleStream(dbN, dStorePos, m, True);
end;

procedure TDataStoreClient_VirtualAuth.GetPostAssembleStreamState(OnResult: TStreamMethod);
begin
  GetBatchStreamState(OnResult);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.GetPostAssembleStreamState(OnResult: TStreamProc);
begin
  GetBatchStreamState(OnResult);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.EndAssembleStream;
begin
  ClearBatchStream;
end;

procedure TDataStoreClient_VirtualAuth.DeleteData(dbN: SystemString; dStorePos: Int64);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(dbN);
  de.WriteInt64(dStorePos);
  SendTunnel.SendDirectStreamCmd('DeleteData', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.FastPostCompleteBuffer(dbN: SystemString; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  p: Pointer;
  siz: NativeUInt;
begin
  p := EncodeOneBuff(dbN, dID, 0, Stream.Memory, Stream.Size, siz);
  SendTunnel.SendCompleteBuffer('FastPostCompleteBuffer', p, siz, True);

  if DoneTimeFree then
      disposeObject(Stream);
end;

procedure TDataStoreClient_VirtualAuth.FastPostCompleteBufferCopy(dbN: SystemString; Stream: TCoreClassStream; dID: Cardinal);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  Stream.Position := 0;
  m.CopyFrom(Stream, Stream.Size);
  m.Position := 0;
  FastPostCompleteBuffer(dbN, m, dID, True);
end;

procedure TDataStoreClient_VirtualAuth.FastPostCompleteBuffer(dbN: SystemString; DataSource: TDataFrameEngine);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.EncodeTo(m, True);
  FastPostCompleteBuffer(dbN, m, c_DF, True);
end;

procedure TDataStoreClient_VirtualAuth.FastPostCompleteBuffer(dbN: SystemString; DataSource: THashVariantList);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastPostCompleteBuffer(dbN, m, c_VL, True);
end;

procedure TDataStoreClient_VirtualAuth.FastPostCompleteBuffer(dbN: SystemString; DataSource: TSectionTextData);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastPostCompleteBuffer(dbN, m, c_TE, True);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.FastPostCompleteBuffer(dbN: SystemString; DataSource: TJsonObject);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastPostCompleteBuffer(dbN, m, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.FastPostCompleteBuffer(dbN: SystemString; DataSource: TPascalString);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, m);
  FastPostCompleteBuffer(dbN, m, c_PascalString, True);
end;

procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  p: Pointer;
  siz: NativeUInt;
begin
  p := EncodeOneBuff(dbN, dID, dStorePos, Stream.Memory, Stream.Size, siz);
  SendTunnel.SendCompleteBuffer('FastInsertCompleteBuffer', p, siz, True);

  if DoneTimeFree then
      disposeObject(Stream);
end;

procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream; dID: Cardinal);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  Stream.Position := 0;
  m.CopyFrom(Stream, Stream.Size);
  m.Position := 0;
  FastInsertCompleteBuffer(dbN, dStorePos, m, dID, True);
end;

procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.EncodeTo(m, True);
  FastInsertCompleteBuffer(dbN, dStorePos, m, c_DF, True);
end;

procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastInsertCompleteBuffer(dbN, dStorePos, m, c_VL, True);
end;

procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastInsertCompleteBuffer(dbN, dStorePos, m, c_TE, True);
end;

{$IFNDEF FPC} procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m, False, TEncoding.UTF8, True);
  FastInsertCompleteBuffer(dbN, dStorePos, m, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.FastInsertCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, m);
  FastInsertCompleteBuffer(dbN, dStorePos, m, c_PascalString, True);
end;

procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; Stream: TMemoryStream64; dID: Cardinal; DoneTimeFree: Boolean);
var
  p: Pointer;
  siz: NativeUInt;
begin
  p := EncodeOneBuff(dbN, dID, dStorePos, Stream.Memory, Stream.Size, siz);
  SendTunnel.SendCompleteBuffer('FastModifyCompleteBuffer', p, siz, True);

  if DoneTimeFree then
      disposeObject(Stream);
end;

procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBufferCopy(dbN: SystemString; dStorePos: Int64; Stream: TCoreClassStream; dID: Cardinal);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  Stream.Position := 0;
  m.CopyFrom(Stream, Stream.Size);
  m.Position := 0;
  FastModifyCompleteBuffer(dbN, dStorePos, m, dID, True);
end;

procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TDataFrameEngine);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.EncodeTo(m, True);
  FastModifyCompleteBuffer(dbN, dStorePos, m, c_DF, True);
end;

procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: THashVariantList);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastModifyCompleteBuffer(dbN, dStorePos, m, c_VL, True);
end;

procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TSectionTextData);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m);
  FastModifyCompleteBuffer(dbN, dStorePos, m, c_TE, True);
end;

{$IFNDEF FPC} procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TJsonObject);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  DataSource.SaveToStream(m, False, TEncoding.UTF8, True);
  FastModifyCompleteBuffer(dbN, dStorePos, m, c_Json, True);
end;
{$ENDIF}


procedure TDataStoreClient_VirtualAuth.FastModifyCompleteBuffer(dbN: SystemString; dStorePos: Int64; DataSource: TPascalString);
var
  m: TMemoryStream64;
begin
  m := TMemoryStream64.Create;
  TDBEnginePascalString.SavePascalStringToStream(@DataSource, m);
  FastModifyCompleteBuffer(dbN, dStorePos, m, c_PascalString, True);
end;

procedure TDataStoreClient_VirtualAuth.GetDBList(OnResult: TStreamMethod);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmd('GetDBList', de, OnResult);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.GetQueryList(OnResult: TStreamMethod);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmd('GetQueryList', de, OnResult);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.GetQueryState(pipeN: SystemString; OnResult: TStreamMethod);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendStreamCmd('GetQueryState', de, OnResult);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.QueryStop(pipeN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendDirectStreamCmd('QueryStop', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.QueryPause(pipeN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendDirectStreamCmd('QueryPause', de);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.QueryPlay(pipeN: SystemString);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendDirectStreamCmd('QueryPlay', de);
  disposeObject(de);
end;

{$IFNDEF FPC}


procedure TDataStoreClient_VirtualAuth.GetDBList(OnResult: TStreamProc);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmd('GetDBList', de, OnResult);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.GetQueryList(OnResult: TStreamProc);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  SendTunnel.SendStreamCmd('GetQueryList', de, OnResult);
  disposeObject(de);
end;

procedure TDataStoreClient_VirtualAuth.GetQueryState(pipeN: SystemString; OnResult: TStreamProc);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.WriteString(pipeN);
  SendTunnel.SendStreamCmd('GetQueryState', de, OnResult);
  disposeObject(de);
end;
{$ENDIF}

end.
