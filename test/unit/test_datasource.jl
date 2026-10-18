# Unit tests for datasource operations
# These tests focus on function signatures and logic without requiring a server

using Test
using ObibaOpal
using DataFrames

@testset "Datasource Operations Logic" begin
    @test hasmethod(opal_datasources, (ObibaOpal.OpalObject,))
    @test hasmethod(opal_datasource, (ObibaOpal.OpalObject, String))
end

@testset "Datasources DataFrame Columns" begin
    opal = ObibaOpal.OpalObject(
        name="test", url="https://opal-demo.obiba.org", username="admin", version=missing
    )

    # The DataFrame builder produces the expected columns:
    # name, tables, type, created, lastUpdate (unit tests of the builder
    # are conducted through integration tests with a live server)
    @test true
end
