# Unit tests for command operations
# These tests focus on function signatures and version guards without requiring a server

using Test
using ObibaOpal

@testset "Command Operations Logic" begin
    @test hasmethod(opal_commands, (ObibaOpal.OpalObject,))
    @test hasmethod(opal_command, (ObibaOpal.OpalObject, String))
    @test hasmethod(opal_command_rm, (ObibaOpal.OpalObject, String))
    @test hasmethod(opal_commands_rm, (ObibaOpal.OpalObject,))
    @test hasmethod(opal_command_result, (ObibaOpal.OpalObject, String))
end

@testset "Command Version Guard" begin
    # commands require Opal 2.1 or higher: a nothing value is returned
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "2.0"),
    )
    @test isnothing(opal_commands(opal))
    @test isnothing(opal_commands_rm(opal))
end

@testset "Command No ID Guard" begin
    # a nothing id short-circuits the version check and returns nothing
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=missing,
    )
    @test isnothing(opal_command(opal, nothing))
    @test isnothing(opal_command_result(opal, nothing))
    @test isnothing(opal_command_rm(opal, nothing))
end

@testset "Command Missing Version Guard" begin
    # a request must have been done to set the Opal version
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=missing,
    )
    @test_throws ErrorException opal_command(opal, "1234")
    @test_throws ErrorException opal_commands(opal)
end
