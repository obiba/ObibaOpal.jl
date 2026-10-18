# Unit tests for symbol operations
# These tests focus on function signatures and error paths without requiring a server

using Test
using ObibaOpal

@testset "Symbol Operations Logic" begin
    @test hasmethod(opal_symbols, (ObibaOpal.OpalObject,))
    @test hasmethod(opal_symbol_rm, (ObibaOpal.OpalObject, String))
    @test hasmethod(opal_rm, (ObibaOpal.OpalObject, String))
    @test hasmethod(opal_symbol_save, (ObibaOpal.OpalObject, String, String))
    @test hasmethod(opal_symbol_import, (ObibaOpal.OpalObject, String, String))
end

@testset "Symbol Save Errors" begin
    # Saving a tibble to a file requires Opal 2.8 or higher
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "2.7"),
    )
    @test_throws ErrorException opal_symbol_save(opal, "D", nothing)

    # compressed SPSS or SAS Transport files require Opal 2.14 or higher
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "2.12"),
    )
    @test_throws ErrorException opal_symbol_save(opal, "D", "test.zsav")
    @test_throws ErrorException opal_symbol_save(opal, "D", "test.xpt")

    # missing destination raises an error
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "5.1"),
    )
    @test_throws ErrorException opal_symbol_save(opal, "D", nothing)
end
