using ObibaOpal
using ObibaOpal: OpalObject
using Test

@testset "login" begin
    opal = opal_login(;
        username="administrator", password="password", url="https://opal-demo.obiba.org"
    )

    @test isa(opal, OpalObject)
end
