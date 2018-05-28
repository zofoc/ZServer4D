program MyCloudServiceDemo;

{$APPTYPE CONSOLE}

{$R *.res}

(*
  �Ʒ�������׼Ⱥ��ģ��
  ֧������ƽ̨��
  Windows��x86/x64 ��Ҫ2012�����Ϸ���������ϵͳ
  Linux��x64 ����ʹ��Ubuntu16.04�����ϰ汾����ϵͳ��Linux����ϵͳ��֧��DIOCP��ICS�ӿڣ�ֻ��ʹ��CrossSocket+Indy��Ϊ�������ӿڣ�

  ע�⣺
  �����Ʒ����������ο����ı�׼ģ��
  MyServer���������滻���ܽ����滻���Զ������֣��Ա�����
  �ڶ��ο�����ɷ���������Ҫ��װһ�׿ͻ��˵�APIЭ��⣬������Ĺ��̽���������ά��
  ����ȷ��������ߺ���Զ����������������Զ��ָ�
*)

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  PascalStrings,
  CoreClasses,
  DoStatusIO,
  ListEngine,
  NotifyObjectBase,
  TextDataEngine,
  CommunicationFramework,
  CommunicationFramework_Server_Indy,
  CommunicationFramework_Client_Indy,
  CommunicationFramework_Server_CrossSocket,
  CommunicationFramework_Client_CrossSocket,
  CommunicationFrameworkDoubleTunnelIO_VirtualAuth,
  CommunicationFrameworkDoubleTunnelIO_NoAuth,
  CommunicationFrameworkDoubleTunnelIO,
  CommunicationFrameworkDataStoreService_VirtualAuth,
  CommunicationFrameworkDataStoreService_NoAuth,
  CommunicationFrameworkDataStoreService,
  CommunicationFrameworkDoubleTunnelIO_ServMan,
  DataFrameEngine,
  UnicodeMixedLib,
  MemoryStream64,
  MyCloudClientAPI in 'MyCloudClientAPI.pas';

const
  // �Ʒ������˿ڣ�˫ͨ�����Զ��壩
  DEFAULT_MYSERVICE_RECVPORT: WORD = 11505;
  DEFAULT_MYSERVICE_SENDPORT: WORD = 11506;

  // �Ʒ��������ͣ��Զ��壩
  MY_SERVERTYPE: TServerType = TServerType.stLogic;

var
  // ȫ�ֱ������󶨵�IP��֧��IPV6
  BIND_IP: string = '0.0.0.0';
  // ȫ�ֱ���������ͨ���Ķ˿ں�
  RECEIVE_PORT: string = '11505';
  // ȫ�ֱ���������ͨ���Ķ˿ں�
  SEND_PORT: string = '11506';

type
  (*
    TMyServer���Լ̳еķ����������6�֣�ÿ�ֿ�ܶ�Ҫ��Ӧ�Ŀͻ��˿�ܣ������������������Ҫ�Լ���װһ����֮��Ӧ�Ŀͻ���
    TCommunicationFramework_DoubleTunnelService_NoAuth: �������֤˫ͨ����ܣ������ڷ�����ͨѶ��Ҳ�����ڿͻ��˷��ʣ�ע�ⰲȫ
    TCommunicationFramework_DoubleTunnelService: �������֤˫ͨ����ܣ������ڿͻ��˵�¼
    TCommunicationFramework_DoubleTunnelService_VirtualAuth: �������֤˫ͨ����ܣ��������֤��֤��Ҫ���ο���
    TDataStoreService_VirtualAuth: �����֤��֤�����ݿ��ܣ��������֤��֤ģ����Ҫ���ο���
    TDataStoreService_NoAuth: �����֤��֤�����ݿ��ܣ������ڷ�����ͨѶ��Ҳ�����ڿͻ��˷��ʣ�ע�ⰲȫ
    TDataStoreService: �������֤˫ͨ�����ݿ��ܣ������ڿͻ��˵�¼
  *)
  TMyServer = class(TCommunicationFramework_DoubleTunnelService_NoAuth, IServerManager_ClientPoolNotify)
  public
    RecvService, SendService: TCommunicationFrameworkServer;
    ManagerClient: TServerManager_ClientPool;
    AntiTimeTick: Double;

    constructor Create;
    destructor Destroy; override;

    // ��ѭ��api
    procedure Progress; override;
    procedure CadencerProgress(Sender: TObject; const deltaTime, newTime: Double); override;

    // ע������
    procedure Command_MyAPI(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
    procedure RegisterCommand; override;
    procedure UnRegisterCommand; override;

    // Service����
    procedure StartService;
    procedure StopService;

    // Զ��ManagerServer��ķ�����ע�������ʱ�����ص��ӿ�
    procedure ServerConfigChange(Sender: TServerManager_Client; ConfigData: TSectionTextData);
    procedure ServerOffline(Sender: TServerManager_Client; RegAddr: SystemString; ServerType: TServerType);
  end;

constructor TMyServer.Create;
begin
  RecvService := TCommunicationFramework_Server_CrossSocket.Create;
  RecvService.PrintParams['AntiIdle'] := False;

  SendService := TCommunicationFramework_Server_CrossSocket.Create;

  ManagerClient := TServerManager_ClientPool.Create(TCommunicationFramework_Client_CrossSocket, Self);
  inherited Create(RecvService, SendService);
end;

destructor TMyServer.Destroy;
begin
  DisposeObject(RecvService);
  DisposeObject(SendService);
  DisposeObject(ManagerClient);
  inherited;
end;

procedure TMyServer.Progress;
begin
  ManagerClient.Progress;
  inherited Progress;

  // ��ɫ���ܻ���
  if RecvService.Count + SendService.Count > 0 then
      CoreClasses.CheckThreadSynchronize(1)
  else
      CoreClasses.CheckThreadSynchronize(100);
end;

procedure TMyServer.CadencerProgress(Sender: TObject; const deltaTime, newTime: Double);
begin
  inherited CadencerProgress(Sender, deltaTime, newTime);

  // ÿ��5�����������ķ���һ��������Ϣ
  AntiTimeTick := AntiTimeTick + deltaTime;
  if AntiTimeTick > 5.0 then
    begin
      AntiTimeTick := 0;
      // ����ĸ�����Ϣ����ʵ��������
      // ������ϢҲ������cpu��ռ���ʣ��ڴ��ռ���ʣ������ռ���ʣ�ϸ��������ʵ��
      // �������Ļ����С�ĸ��ط�������ַ���߿ͻ��ˣ��Ӷ�ʵ�ֲַ�ʽ����
      // ��������崻����������Ļ��Զ��ӵ��ȱ���ɾ����̨����������Ϣ���Ӷ���ǿ��̨�ȶ���
      ManagerClient.AntiIdle(RecvTunnel.Count + SendTunnel.Count);
    end;
end;

// ע������
procedure TMyServer.Command_MyAPI(Sender: TPeerIO; InData, OutData: TDataFrameEngine);
begin
  OutData.WriteInteger(InData.Reader.ReadInteger + InData.Reader.ReadInteger);
end;

procedure TMyServer.RegisterCommand;
begin
  inherited RegisterCommand;
  // �ڴ˴�ע���Լ�������
  RecvTunnel.RegisterStream('MyAPI').OnExecute := Command_MyAPI;
end;

procedure TMyServer.UnRegisterCommand;
begin
  inherited UnRegisterCommand;
  // �ڴ˴�ɾ���Լ���ע������
  RecvTunnel.DeleteRegistedCMD('MyAPI');
end;

procedure TMyServer.StartService;
begin
  StopService;
  if RecvService.StartService(BIND_IP, umlStrToInt(RECEIVE_PORT, DEFAULT_MYSERVICE_RECVPORT)) then
      DoStatus('Receive tunnel ready Ok! bind:%s port:%s', [TranslateBindAddr(BIND_IP), RECEIVE_PORT])
  else
      DoStatus('Receive tunnel Failed! bind:%s port:%s', [TranslateBindAddr(BIND_IP), RECEIVE_PORT]);

  if SendService.StartService(BIND_IP, umlStrToInt(SEND_PORT, DEFAULT_MYSERVICE_SENDPORT)) then
      DoStatus('Send tunnel ready Ok! bind:%s port:%s', [TranslateBindAddr(BIND_IP), SEND_PORT])
  else
      DoStatus('Send tunnel Failed! bind:%s port:%s', [TranslateBindAddr(BIND_IP), SEND_PORT]);;

  RegisterCommand;
  AntiTimeTick := 0;
end;

procedure TMyServer.StopService;
begin
  try
    RecvService.StopService;
    SendService.StopService;
  except
  end;
  UnRegisterCommand;
end;

// Զ��ManagerServer��ķ�����ע�������ʱ�����ص��ӿ�
procedure TMyServer.ServerConfigChange(Sender: TServerManager_Client; ConfigData: TSectionTextData);
begin
end;

procedure TMyServer.ServerOffline(Sender: TServerManager_Client; RegAddr: SystemString; ServerType: TServerType);
begin
end;

// ȫ�ֵ�ʵ������
var
  Server: TMyServer;

  // �ӳٿ����˿�����
procedure PostExecute_DelayStartService(Sender: TNPostExecute);
begin
  Server.StartService;
end;

// �ӳ����������ע��
procedure PostExecute_DelayRegService(Sender: TNPostExecute);
  procedure AutoConnectManagerServer(AClients: TServerManager_ClientPool; ManServAddr, RegAddr: SystemString;
    RegRecvPort, RegSendPort: WORD; ServerType: TServerType);
  begin
    AClients.BuildClientAndConnect(serverType2Str(ServerType),
      ManServAddr, RegAddr,
      DEFAULT_MANAGERSERVICE_SENDPORT, DEFAULT_MANAGERSERVICE_RECVPORT,
      RegRecvPort, RegSendPort, ServerType);
  end;

begin
  AutoConnectManagerServer(Server.ManagerClient,
    Sender.Data3, Sender.Data4,
    umlStrToInt(SEND_PORT, DEFAULT_MYSERVICE_SENDPORT),
    umlStrToInt(RECEIVE_PORT, DEFAULT_MYSERVICE_RECVPORT), MY_SERVERTYPE);
end;

// ������������
procedure FillParameter;
var
  i, pcount: Integer;
  p1, p2: SystemString;

  delayStartService: Boolean;
  delayStartServiceTime: Double;

  delayReg: Boolean;
  delayRegTime: Double;
  ManServAddr: SystemString;
  RegAddr: SystemString;
begin
  RECEIVE_PORT := IntToStr(DEFAULT_MYSERVICE_RECVPORT);
  SEND_PORT := IntToStr(DEFAULT_MYSERVICE_SENDPORT);

  delayStartService := True;
  delayStartServiceTime := 0.1;

  delayRegTime := 1.0;

  try
    pcount := ParamCount;
    for i := 1 to pcount do
      begin
        p1 := ParamStr(i);
        if p1 <> '' then
          begin
            if umlMultipleMatch(['Recv:*', 'r:*', 'Receive:*', '-r:*', '-recv:*', '-receive:*'], p1) then
              begin
                p2 := umlDeleteFirstStr(p1, ':');
                if umlIsNumber(p2) then
                    RECEIVE_PORT := p2;
              end;

            if umlMultipleMatch(['Send:*', 's:*', '-s:*', '-Send:*'], p1) then
              begin
                p2 := umlDeleteFirstStr(p1, ':');
                if umlIsNumber(p2) then
                    SEND_PORT := p2;
              end;

            if umlMultipleMatch(['ipv6', '-6', '-ipv6', '-v6'], p1) then
              begin
                BIND_IP := '::';
              end;

            if umlMultipleMatch(['ipv4', '-4', '-ipv4', '-v4'], p1) then
              begin
                BIND_IP := '0.0.0.0';
              end;

            if umlMultipleMatch(['ipv4+ipv6', '-4+6', '-ipv4+ipv6', '-v4+v6', 'ipv6+ipv4', '-ipv6+ipv4', '-6+4', '-v6+v4'], p1) then
              begin
                BIND_IP := '';
              end;

            if umlMultipleMatch(['DelayStart:*', 'DelayService:*', '-DelayStart:*', '-DelayService:*'], p1) then
              begin
                delayStartService := True;
                p2 := umlDeleteFirstStr(p1, ':');
                if umlIsNumber(p2) then
                    delayStartServiceTime := umlStrToFloat(p2, 1);
              end;

            if umlMultipleMatch(['DelayStart', 'DelayService', 'AutoStart', 'AutoService',
              '-DelayStart', '-DelayService', '-AutoStart', '-AutoService'], p1) then
              begin
                delayStartService := True;
                delayStartServiceTime := 1.0;
              end;

            if umlMultipleMatch(['Server:*', 'Manager:*', 'ManServ:*', 'ManServer:*',
              '-Server:*', '-Manager:*', '-ManServ:*', '-ManServer:*'], p1) then
              begin
                ManServAddr := umlTrimSpace(umlDeleteFirstStr(p1, ':'));
              end;

            if umlMultipleMatch(['RegAddress:*', 'RegistedAddress:*', 'RegAddr:*', 'RegistedAddr:*',
              '-RegAddress:*', '-RegistedAddress:*', '-RegAddr:*', '-RegistedAddr:*'], p1) then
              begin
                delayReg := True;
                RegAddr := umlTrimSpace(umlDeleteFirstStr(p1, ':'));
              end;

            if umlMultipleMatch(['DelayRegManager:*', 'DelayReg:*', 'DelayRegisted:*', 'DelayRegMan:*',
              '-DelayRegManager:*', '-DelayReg:*', '-DelayRegisted:*', '-DelayRegMan:*'], p1) then
              begin
                delayReg := True;
                p2 := umlDeleteFirstStr(p1, ':');
                if umlIsNumber(p2) then
                    delayRegTime := umlStrToFloat(p2, 1);
              end;
          end;
      end;
  except
  end;

  if delayStartService then
    begin
      with Server.ProgressEngine.PostExecute(delayStartServiceTime) do
          OnExecuteCall := PostExecute_DelayStartService;
    end;

  if delayReg then
    with Server.ProgressEngine.PostExecute(delayRegTime) do
      begin
        Data3 := ManServAddr;
        Data4 := RegAddr;
        OnExecuteCall := PostExecute_DelayRegService;
      end;

  DoStatus('');
end;

begin
  Server := TMyServer.Create;

  // ������������
  FillParameter;

  // ��ѭ��
  while True do
      Server.Progress; // ��������ɫ���ܻ���

  Server.StopService;
  DisposeObject(Server);

end.
