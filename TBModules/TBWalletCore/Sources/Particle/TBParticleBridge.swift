
import ParticleNetworkBase
import ParticleAuthService
import ParticleWalletAPI
import RxSwift

public class TBParticleBridge {
    
    public static let shared = TBParticleBridge()
    
    private let bag = DisposeBag()
    
    public func test() {
        
        if ParticleNetwork.getDevEnv() == .production {
            print("111")
        }
        
        ParticleAuthService.login(type: .jwt, account: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvdGVzdGluZy5hbHBoYWdyYW0uYXBwXC9hcGlcL3YyXC9wYXNzcG9ydFwvbG9naW4iLCJpYXQiOjE2NzE3ODIzNTYsImV4cCI6MTY3ODk4MjM1NiwibmJmIjoxNjcxNzgyMzU2LCJqdGkiOiI3bnhON1l2OGNnYmMyYjFBIiwic3ViIjoyOCwicHJ2IjoiNDFkZjg4MzRmMWI5OGY3MGVmYTYwYWFlZGVmNDIzNDEzNzAwNjkwYyJ9.Qc-MPSisGUT2Bilv-4eT_ZCDD_Fp0CnzU3KxjPys_iHimtdhWjoNW3yu89l_PKzr-P_JOfRFgTpbBYUHrDxReZoIF_3_VMa58q6Ppodhb95z3sGE23XBCDQaWlbs4Z2oxxG_VRamypHrhhcbc-ekasU43JQCLlYJy_660s5pJovCnCjHF3ZSvocnRCvSmXS66zDEtNgN-Wa9gitW_6mOeYbmx2UzvvuKHFyJZepQzfqfePXdMazq4x2d7TtJhG6vmi4tQZE7j4atdDEqOfuVniQZ_yIHnOw7eXMMBa9I99FIdoNR_gC4FbGIwBDOrac0JugSvDTTpt1xiKyYiiZJVw").subscribe(onSuccess: { info in
            debugPrint(info)
        }, onFailure: { error in
            debugPrint(error)
        }).disposed(by: self.bag)
        
        try? ParticleWalletAPI.getTokens(address: "0x352e40B46ec304B929bfC492d9FD7fA2B2E33356", chainInfo: .ethereum(.mainnet)) { models in
            
        }
        
    }
    
}
