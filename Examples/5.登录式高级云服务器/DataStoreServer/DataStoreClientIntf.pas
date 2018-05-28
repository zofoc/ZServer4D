unit DataStoreClientIntf;

interface

uses Variants, SysUtils, Types, DateUtils,
  CommunicationFrameworkDoubleTunnelIO_NoAuth,
  CoreClasses, TextDataEngine, ListEngine, CommunicationFramework,
  DoStatusIO, UnicodeMixedLib, DataFrameEngine, Cadencer,
  NotifyObjectBase,
  CommunicationFramework_Client_CrossSocket,
  CommunicationFramework_Client_ICS,
  CommunicationFrameworkDataStoreService_NoAuth, PascalStrings,
  MemoryStream64, ZDBEngine, ZDBLocalManager;

const
  cUserLoginInfoDB = 'UserLoginInfo'; // ��¼��ʷ��Ϣ
  cUserMessageDB   = 'UserMessageDB'; // �û����Ժ���Ϣ
  cLogDB           = 'LogDB';         // Log���ݿ�
  cFogComputeDB    = 'FogHistoryDB';  // �������ʷ���ݿ�

type
  TDataStoreCliConnectInfo = record
    DBServAddr: SystemString;
    DBCliRecvPort, DBCliSendPort: Word;
  end;

  TDataStore_DoubleTunnelClient_GetValue = reference to procedure(Successed: Boolean; Obj: TCoreClassObject; Comment: string; Value: Int64);
  TObjectStateProc                       = reference to procedure(Obj: TCoreClassObject; const State: Boolean);
  TQueryReplayStateProc                  = reference to procedure(ReplayData: TDataFrameEngine);

  TDataStore_DoubleTunnelClient = class(TDataStoreClient_NoAuth)
  protected
  public
    NetRecvTunnelIntf, NetSendTunnelIntf: TCommunicationFrameworkClient;
    ConnectInfo                         : TDataStoreCliConnectInfo;
    ReconnectTotal                      : Integer;

    constructor Create(ClientClass: TCommunicationFrameworkClientClass);
    destructor Destroy; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    function Connect(addr: SystemString; const DBCliRecvPort, DBCliSendPort: Word): Boolean; override;
    procedure Disconnect; override;

    procedure AntiIdle(workLoad: Word);

    procedure Progress; override;

    procedure ExistsUserLoginInfo(UserID: SystemString; UserObjWithProc: TCoreClassObject; BackcallStateProc: TObjectStateProc);
    procedure PostUserLoginInfo(UserID, UserAlias: SystemString; Comment: string);

    procedure PostLogInfo(LogTyp, LogS: string);

    procedure PostFogComputeInfo(UserID, UserAlias, Exp, ComputeValue: string);
  end;

implementation

constructor TDataStore_DoubleTunnelClient.Create(ClientClass: TCommunicationFrameworkClientClass);
begin
  NetRecvTunnelIntf := ClientClass.Create;
  NetSendTunnelIntf := ClientClass.Create;
  NetSendTunnelIntf.PrintParams['AntiIdle'] := False;
  ConnectInfo.DBServAddr := '';
  ConnectInfo.DBCliRecvPort := 0;
  ConnectInfo.DBCliSendPort := 0;
  ReconnectTotal := 0;
  inherited Create(NetRecvTunnelIntf, NetSendTunnelIntf);

  SwitchAsMaxPerformance;
end;

destructor TDataStore_DoubleTunnelClient.Destroy;
begin
  Disconnect;
  DisposeObject(NetRecvTunnelIntf);
  DisposeObject(NetSendTunnelIntf);
  inherited Destroy;
end;

procedure TDataStore_DoubleTunnelClient.RegisterCommand;
begin
  inherited RegisterCommand;
end;

procedure TDataStore_DoubleTunnelClient.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
end;

function TDataStore_DoubleTunnelClient.Connect(addr: SystemString; const DBCliRecvPort, DBCliSendPort: Word): Boolean;
var
  t: Cardinal;
begin
  Result := False;
  Disconnect;

  if not NetSendTunnelIntf.Connect(addr, DBCliSendPort) then
    begin
      DoStatus('connect %s failed!', [addr]);
      exit;
    end;
  if not NetRecvTunnelIntf.Connect(addr, DBCliRecvPort) then
    begin
      DoStatus('connect %s failed!', [addr]);
      exit;
    end;

  if not Connected then
      exit;

  t := TCoreClassThread.GetTickCount + 4000;
  while not RemoteInited do
    begin
      if TCoreClassThread.GetTickCount > t then
          break;
      if not Connected then
          break;
      Progress;
    end;

  if Connected then
    begin
      DoStatus('connect DataStore service "%s" ok!', [addr]);
      Result := TunnelLink;

      if Result then
        begin
          ConnectInfo.DBServAddr := addr;
          ConnectInfo.DBCliRecvPort := DBCliRecvPort;
          ConnectInfo.DBCliSendPort := DBCliSendPort;
        end;
    end;
end;

procedure TDataStore_DoubleTunnelClient.Disconnect;
begin
  NetSendTunnelIntf.Disconnect;
  NetRecvTunnelIntf.Disconnect;
end;

procedure TDataStore_DoubleTunnelClient.AntiIdle(workLoad: Word);
var
  sendDE: TDataFrameEngine;
begin
  if not Connected then
      exit;
  sendDE := TDataFrameEngine.Create;
  sendDE.WriteWORD(workLoad);
  SendTunnel.SendDirectStreamCmd('AntiIdle', sendDE);
  DisposeObject(sendDE);
end;

procedure TDataStore_DoubleTunnelClient.Progress;
begin
  inherited Progress;
end;

procedure TDataStore_DoubleTunnelClient.ExistsUserLoginInfo(UserID: SystemString; UserObjWithProc: TCoreClassObject; BackcallStateProc: TObjectStateProc);
var
  usrVL: THashVariantList;
begin
  if not Connected then
      exit;
  if not Assigned(BackcallStateProc) then
      exit;

  usrVL := THashVariantList.Create;
  usrVL['UserID'] := UserID;
  QueryDB('OnlyUserNameQuery', False, False, True, True, cUserLoginInfoDB, '', 0.1, 0, 1,
    usrVL,
    nil,
    procedure(dbN, outN, pipeN: SystemString; TotalResult: Int64)
    begin
      BackcallStateProc(UserObjWithProc, TotalResult > 0);
    end);
  DisposeObject(usrVL);
end;

procedure TDataStore_DoubleTunnelClient.PostUserLoginInfo(UserID, UserAlias: SystemString; Comment: string);
var
  vl: THashVariantList;
begin
  if not Connected then
      exit;
  DisableStatus;
  try
    vl := THashVariantList.Create;
    vl['UserID'] := UserID;
    vl['Alias'] := UserAlias;
    vl['comment'] := Comment;
    vl['Date'] := Date;
    vl['Time'] := Time;
    BeginAssembleStream;
    PostAssembleStream(cUserLoginInfoDB, vl);
    EndAssembleStream;
    DisposeObject(vl);
  finally
      EnabledStatus
  end;
end;

procedure TDataStore_DoubleTunnelClient.PostLogInfo(LogTyp, LogS: string);
var
  vl: THashVariantList;
begin
  if not Connected then
      exit;

  DisableStatus;
  try
    vl := THashVariantList.Create;
    vl['Date'] := Date;
    vl['Time'] := Time;
    vl['Type'] := LogTyp;
    vl['Log'] := LogS;
    BeginAssembleStream;
    PostAssembleStream(cLogDB, vl);
    EndAssembleStream;
    DisposeObject(vl);
  finally
      EnabledStatus
  end;
end;

procedure TDataStore_DoubleTunnelClient.PostFogComputeInfo(UserID, UserAlias, Exp, ComputeValue: string);
var
  vl: THashVariantList;
begin
  if not Connected then
      exit;

  DisableStatus;
  try
    vl := THashVariantList.Create;
    vl['Date'] := Date;
    vl['Time'] := Time;
    vl['UserID'] := UserID;
    vl['UserAlias'] := UserAlias;
    vl['Exp'] := Exp;
    vl['ComputeValue'] := ComputeValue;
    BeginAssembleStream;
    PostAssembleStream(cFogComputeDB, vl);
    EndAssembleStream;
    DisposeObject(vl);
  finally
      EnabledStatus
  end;
end;

end.
