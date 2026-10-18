# Unit tests for assignment operations
# These tests focus on function signatures and error paths without requiring a server

using Test
using ObibaOpal

@testset "Assignment Operations Logic" begin
    @test hasmethod(opal_assign, (ObibaOpal.OpalObject, String, Any))
    @test hasmethod(opal_assign_table, (ObibaOpal.OpalObject, String, String))
    @test hasmethod(opal_assign_table_tibble, (ObibaOpal.OpalObject, String, String))
    @test hasmethod(opal_assign_script, (ObibaOpal.OpalObject, String, String))
    @test hasmethod(opal_assign_resource, (ObibaOpal.OpalObject, String, String))
end

@testset "Assign Resource Version Guard" begin
    # resources require Opal 3.0 or higher
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "2.9"),
    )
    @test_throws ErrorException opal_assign_resource(opal, "D", "datashield.CNSIM1r")
end

@testset "Assign Data JSON Script" begin
    # data values are serialized as JSON and assigned via an R script with jsonlite
    # (same approach as the Opal Python client), not as x-rdata (R serialize format
    # that Julia cannot produce)
    src = read(joinpath(dirname(@__DIR__), "..", "src", "opal_assign.jl"), String)
    @test occursin("application/x-rscript", src)
    @test occursin("jsonlite::fromJSON", src)
    @test occursin("jsonlite::base64_dec", src)
    @test !occursin("application/x-rdata", src)
    @test !occursin("using Serialization", src)
end
