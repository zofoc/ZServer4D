unit MyCloudClientAPI;

interface

uses Variants, SysUtils, Types, DateUtils,
  CoreClasses, TextDataEngine, ListEngine, CommunicationFramework,
  DoStatusIO, UnicodeMixedLib, DataFrameEngine, Cadencer,
  NotifyObjectBase,
  CommunicationFramework_Client_Indy,
  PascalStrings, MemoryStream64,
  CommunicationFrameworkDoubleTunnelIO_VirtualAuth,
  CommunicationFrameworkDoubleTunnelIO_NoAuth,
  CommunicationFrameworkDoubleTunnelIO,
  CommunicationFrameworkDataStoreService_VirtualAuth,
  CommunicationFrameworkDataStoreService_NoAuth,
  CommunicationFrameworkDataStoreService;

type
  (*
    TMyCloudClient���Լ̳еĿͻ��˻��������6�֣�ÿ�ֿ�ܶ�Ҫ��Ӧ�ķ������˿��
    TCommunicationFramework_DoubleTunnelClient_NoAuth: �������֤˫ͨ�����
    TCommunicationFramework_DoubleTunnelClient: �������֤˫ͨ�����
    TCommunicationFramework_DoubleTunnelClient_VirtualAuth: �������֤˫ͨ����ܣ��������֤��֤��Ҫ���ο���
    TDataStoreClient_VirtualAuth: �����֤��֤�����ݿ��ܣ��������֤��֤ģ����Ҫ���ο���
    TDataStoreClient_NoAuth: �����֤��֤�����ݿ���
    TDataStoreClient: �������֤˫ͨ�����ݿ���
  *)
  TMyCloudClient = class(TCommunicationFramework_DoubleTunnelClient)
  protected
  public
    NetRecvTunnelIntf, NetSendTunnelIntf: TCommunicationFrameworkClient;

    constructor Create(ClientClass: TCommunicationFrameworkClientClass);
    destructor Destroy; override;

    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    // ����ʹ�ô������֤��֤�Ŀ�ܣ���Connect���һ����Ҫ��һ�����֤��֤���ܽ���TunnelLink����������ϸ���뵽������ȥ�鿴
    function Connect(addr: SystemString; const FogCliRecvPort, FogCliSendPort: Word): Boolean; override;

    procedure Disconnect; override;

    function MyAPI(a, b: Integer): Integer;
  end;

implementation

constructor TMyCloudClient.Create(ClientClass: TCommunicationFrameworkClientClass);
begin
  NetRecvTunnelIntf := ClientClass.Create;
  NetSendTunnelIntf := ClientClass.Create;
  NetSendTunnelIntf.PrintParams['AntiIdle'] := False;
  inherited Create(NetRecvTunnelIntf, NetSendTunnelIntf);
  RegisterCommand;
end;

destructor TMyCloudClient.Destroy;
begin
  UnRegisterCommand;
  Disconnect;
  DisposeObject(NetRecvTunnelIntf);
  DisposeObject(NetSendTunnelIntf);
  inherited Destroy;
end;

procedure TMyCloudClient.RegisterCommand;
begin
  inherited RegisterCommand;
end;

procedure TMyCloudClient.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
end;

function TMyCloudClient.Connect(addr: SystemString; const FogCliRecvPort, FogCliSendPort: Word): Boolean;
var
  t: Cardinal;
begin
  Result := False;
  Disconnect;

  if not NetSendTunnelIntf.Connect(addr, FogCliSendPort) then
    begin
      DoStatus('connect %s failed!', [addr]);
      exit;
    end;
  if not NetRecvTunnelIntf.Connect(addr, FogCliRecvPort) then
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
      DoStatus('connect fog compute service "%s" ok!', [addr]);

      // ����ʹ�ô������֤��֤�Ŀ�ܣ�������Ҫ��һ�����֤��֤���ܽ���TunnelLink����
      // if UserLogin(UserID, Passwd) then
      // Result := TunnelLink;

      // ��Ϊģ�͵���ʾʹ��NoAuth��ܣ�����ֱ����TunnelLink������
      Result := TunnelLink;
    end;
end;

procedure TMyCloudClient.Disconnect;
begin
  NetSendTunnelIntf.Disconnect;
  NetRecvTunnelIntf.Disconnect;
end;

function TMyCloudClient.MyAPI(a, b: Integer): Integer;
var
  SendDE, ResultDE: TDataFrameEngine;
begin
  Result := 0;
  if not Connected then
      exit;
  if not LinkOk then
      exit;

  SendDE := TDataFrameEngine.Create;
  ResultDE := TDataFrameEngine.Create;

  SendDE.WriteInteger(a);
  SendDE.WriteInteger(b);

  SendTunnel.WaitSendStreamCmd('MyAPI', SendDE, ResultDE, 5000);

  Result := ResultDE.Reader.ReadInteger;

  DisposeObject([SendDE, ResultDE]);
end;

end.
