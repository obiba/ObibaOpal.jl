# Unit tests for utility functions
# These tests focus on internal helper functions and don't require a server connection

using Test
using ObibaOpal
using HTTP
using JSON
using MbedTLS

@testset "URL Cleaning" begin
    # Test cleaning multiple slashes in URLs
    expected = "https://opal.example.org/ws/files/some/path/to/file"
    @test ObibaOpal._cleanUrl("https://opal.example.org/ws/files/some///path/to//file") ==
        expected

    expected = "http://localhost:8080/ws/files/some/path/to/file"
    @test ObibaOpal._cleanUrl("http://localhost:8080/ws/files/some///path/to//file") ==
        expected

    # Test with single slashes (should remain unchanged)
    url = "https://opal-demo.obiba.org/ws/datasource/CNSIM/table/CNSIM1"
    @test ObibaOpal._cleanUrl(url) == url

    # Test with trailing slashes (should remain unchanged - _cleanUrl doesn't strip trailing slashes)
    @test ObibaOpal._cleanUrl("https://example.org/ws/files/") ==
        "https://example.org/ws/files/"
end

@testset "URL Construction" begin
    # Create a minimal OpalObject for testing
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )

    # Test basic URL construction
    url = ObibaOpal._url(opal, "datasource", "CNSIM", "table", "CNSIM1")
    @test occursin("https://opal-demo.obiba.org", url)
    @test occursin("/datasource/CNSIM/table/CNSIM1", url)

    # Test URL construction with single argument
    url = ObibaOpal._url(opal, "projects")
    @test occursin("https://opal-demo.obiba.org", url)
    @test occursin("/projects", url)

    # Test URL construction with multiple segments
    url = ObibaOpal._url(opal, "project", "RSRC", "resources")
    @test occursin("https://opal-demo.obiba.org", url)
    @test occursin("/project/RSRC/resources", url)
end

@testset "Null to NA Conversion" begin
    # Test nothing conversion
    @test ismissing(ObibaOpal._nullToNA(nothing))

    # Test non-nothing values remain unchanged
    @test ObibaOpal._nullToNA("test") == "test"
    @test ObibaOpal._nullToNA(123) == 123
    @test ObibaOpal._nullToNA(true) == true
    @test ObibaOpal._nullToNA([1, 2, 3]) == [1, 2, 3]
end

@testset "Empty Check" begin
    # Test nothing is empty
    @test ObibaOpal._isempty(nothing) == true

    # Test missing is empty
    @test ObibaOpal._isempty(missing) == true

    # Test empty string is empty
    @test ObibaOpal._isempty("") == true

    # Test empty array is empty
    @test ObibaOpal._isempty([]) == true

    # Test non-empty values
    @test ObibaOpal._isempty("test") == false
    @test ObibaOpal._isempty([1, 2, 3]) == false
    @test ObibaOpal._isempty(123) == false
    @test ObibaOpal._isempty(0) == false
end

@testset "Response Content Parsing" begin
    # Create a minimal OpalObject for testing
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )

    # Test JSON content parsing
    json_data = Dict("name" => "CNSIM1", "entityType" => "Participant", "count" => 100)
    json_string = JSON.json(json_data)

    # Mock response with JSON content-type
    mock_resp = Dict(
        "status" => 200,
        "headers" => Dict("content-type" => "application/json"),
        "body" => json_string,
    )

    # Note: We can't fully test _getContent without mocking HTTP.content()
    # but we can test that JSON parsing works
    parsed = JSON.parse(json_string)
    @test parsed["name"] == "CNSIM1"
    @test parsed["entityType"] == "Participant"
    @test parsed["count"] == 100
end

@testset "Session Helpers" begin
    # Test session ID extraction patterns
    # These would normally come from HTTP cookies
    cookies = [Dict("name" => "opalsid", "value" => "abc123def456")]
    # Note: _extractOpalSessionId requires actual HTTP.Cookies format
    # This is a conceptual test showing what we expect
    @test cookies[1]["value"] == "abc123def456"

    # Note: _newSession requires an OpalObject and makes HTTP requests,
    # so it's tested in integration tests instead
end

@testset "Session Cookie Extraction" begin
    response = HTTP.Response(
        200,
        [
            "Set-Cookie" => "opalsid=abc123; Path=/",
            "Set-Cookie" => "XSRF-TOKEN=tok456; Path=/",
        ],
    )
    @test ObibaOpal._extractOpalSessionId(response) == "abc123"
    @test ObibaOpal._extractOpalCSRFToken(response) == "tok456"

    # no cookies returns nothing
    response = HTTP.Response(200)
    @test isnothing(ObibaOpal._extractOpalSessionId(response))
    @test isnothing(ObibaOpal._extractOpalCSRFToken(response))
end

@testset "Version Compare" begin
    opal = ObibaOpal.OpalObject(version=parse(VersionNumber, "5.1.4"))
    @test ObibaOpal._versionCompare(opal, "5.1") == 1
    @test ObibaOpal._versionCompare(opal, "5.1.4") == 0
    @test ObibaOpal._versionCompare(opal, "5.0") == 1
    @test ObibaOpal._versionCompare(opal, "5.2") == -1
    @test ObibaOpal._versionCompare(opal, "3.2") == 1

    # prerelease versions are compared without their pre-release suffix
    opal = ObibaOpal.OpalObject(version=parse(VersionNumber, "5.1.4-rc1"))
    @test ObibaOpal._versionCompare(opal, "5.1.4") == 0
    @test ObibaOpal._versionCompare(opal, "5.1.3") == 1
    @test ObibaOpal._versionCompare(opal, "5.1.5") == -1

    # missing version raises an error
    opal = ObibaOpal.OpalObject(version=missing)
    @test_throws ErrorException ObibaOpal._versionCompare(opal, "5.1")
end

@testset "List To JSON" begin
    @test ObibaOpal._listToJson(Dict("a" => "b")) == "{\"a\": \"b\"}"
    @test ObibaOpal._listToJson(["x", "y"]) == "[\"x\",\"y\"]"
    @test ObibaOpal._listToJson(Dict("n" => true)) == "{\"n\": true}"
    @test ObibaOpal._listToJson(Dict("n" => false)) == "{\"n\": false}"
    @test ObibaOpal._listToJson(42) == "\"42\""
    @test ObibaOpal._listToJson("v") == "\"v\""
end

@testset "Deparse" begin
    @test ObibaOpal._deparse("c(1, 2, 3)") == "c(1, 2, 3)"
    @test ObibaOpal._deparse(:(a + b)) == "a + b"
end

@testset "Extract Label" begin
    labels = [
        Dict("name" => "label", "locale" => "en", "value" => "Age"),
        Dict("name" => "label", "locale" => "fr", "value" => "Âge"),
    ]
    @test ObibaOpal._extractLabel("en", labels) == "Age"
    @test ObibaOpal._extractLabel("fr", labels) == "Âge"
    # fallback to undefined locale label
    labels = [Dict("name" => "label", "value" => "Age")]
    @test ObibaOpal._extractLabel("en", labels) == "Age"
    # no labels
    @test ismissing(ObibaOpal._extractLabel("en", []))
end

@testset "Split Attribute Key" begin
    attr = ObibaOpal._splitAttributeKey("ns::name")
    @test attr["namespace"] == "ns"
    @test attr["name"] == "name"
    @test !haskey(attr, "locale")

    attr = ObibaOpal._splitAttributeKey("ns::name:en")
    @test attr["namespace"] == "ns"
    @test attr["name"] == "name"
    @test attr["locale"] == "en"

    attr = ObibaOpal._splitAttributeKey("label")
    @test !haskey(attr, "namespace")
    @test attr["name"] == "label"
    @test !haskey(attr, "locale")

    attr = ObibaOpal._splitAttributeKey("label:en")
    @test !haskey(attr, "namespace")
    @test attr["name"] == "label"
    @test attr["locale"] == "en"
end

@testset "Merge Char Vectors" begin
    left = ["a", "b"]
    right = ["x | y", "c"]
    merged = ObibaOpal._mergeCharVectors(left, right)
    @test merged[1] == "a | x | y"
    @test merged[2] == "b | c"
end

@testset "Norm to NA String" begin
    @test ObibaOpal._norm2nastr("value") == "value"
    @test ObibaOpal._norm2nastr(nothing) == "N/A"
    @test ObibaOpal._norm2nastr("") == "N/A"
    @test ObibaOpal._norm2nastr(123) == "123"
end

@testset "Localize to String" begin
    item = [
        Dict("locale" => "en", "text" => "hello"),
        Dict("locale" => "fr", "text" => "bonjour"),
    ]
    @test ObibaOpal._localized2str(item, "fr") == "bonjour"
    @test ObibaOpal._localized2str(item, "en") == "hello"
    @test ObibaOpal._localized2str(item, "de") == ""
end

@testset "Show Opal Object" begin
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        version=parse(VersionNumber, "5.1"),
        rid="session-rid",
        profile="default",
    )
    printed = sprint(show, MIME"text/plain"(), opal)
    @test occursin("url: https://opal-demo.obiba.org", printed)
    @test occursin("name: test", printed)
    @test occursin("version: 5.1", printed)
    @test occursin("username: admin", printed)
    @test occursin("rid: session-rid", printed)
    @test occursin("profile: default", printed)
end

@testset "Task Id From Location" begin
    # accepts values with or without leading slash, and full URLs
    @test ObibaOpal._taskIdFromLocation("/shell/command/42") == "42"
    @test ObibaOpal._taskIdFromLocation("shell/command/42") == "42"
    @test ObibaOpal._taskIdFromLocation("/ws/shell/command/42") == "42"
    @test ObibaOpal._taskIdFromLocation("https://opal.example.org/ws/shell/command/42") ==
        "42"
    @test ObibaOpal._taskIdFromLocation("https://opal.example.org/shell/command/42") == "42"
    @test ObibaOpal._taskIdFromLocation("") isa Nothing
end

@testset "Attachment Filename" begin
    # quoted form
    @test ObibaOpal._attachmentFilename("attachment; filename=\"data.csv\"") == "data.csv"
    # unquoted form (throws with the old split-on-quotes parsing)
    @test ObibaOpal._attachmentFilename("attachment; filename=data.csv") == "data.csv"
    # RFC 5987 extended form
    @test ObibaOpal._attachmentFilename("attachment; filename*=UTF-8''d%20ata.csv") ==
        "d ata.csv"
    # quoted with additional parameters
    @test ObibaOpal._attachmentFilename("attachment; filename=\"my file.csv\"; size=12") ==
        "my file.csv"
    # no filename
    @test ObibaOpal._attachmentFilename("attachment") isa Nothing
end

@testset "Request Config Mapping" begin
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal.example.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )
    # empty config: no kwargs
    @test ObibaOpal._requestConfig(opal) == Pair{Symbol,Any}[]

    # non-empty opts must not throw a Dict conversion error (config is
    # Dict{String,Any} and opts were assigned as Dict{String,Any})
    opal.config = Dict{String,Any}("readtimeout" => 60)
    @test ObibaOpal._requestConfig(opal) == [:readtimeout => 60]

    # require_ssl_verification=false -> sslconfig with verify off
    opal.config = Dict{String,Any}("require_ssl_verification" => false)
    kwargs = ObibaOpal._requestConfig(opal)
    @test length(kwargs) == 1
    @test kwargs[1].first == :sslconfig
    @test kwargs[1].second isa MbedTLS.SSLConfig

    # curl-style: ssl_verifypeer=false -> same
    opal.config = Dict{String,Any}("ssl_verifypeer" => false)
    kwargs = ObibaOpal._requestConfig(opal)
    @test length(kwargs) == 1 && kwargs[1].first == :sslconfig

    # ssl_verifyhost=false -> same
    opal.config = Dict{String,Any}("ssl_verifyhost" => false)
    kwargs = ObibaOpal._requestConfig(opal)
    @test length(kwargs) == 1 && kwargs[1].first == :sslconfig

    # cainfo triggers sslconfig build; missing file errors
    opal.config = Dict{String,Any}("cainfo" => "/nonexistent/ca.pem")
    @test_throws ErrorException ObibaOpal._requestConfig(opal)
end

@testset "Attachment Response Handling" begin
    opal = ObibaOpal.OpalObject(
        name="test",
        url="https://opal.example.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )
    # unquoted filename in Content-Disposition must not throw
    resp = HTTP.Response(
        200,
        [
            "Content-Type" => "text/csv",
            "Content-Disposition" => "attachment; filename=data.csv",
        ];
        body="a,b\n1,2\n",
    )
    content = ObibaOpal._handleResponse!(opal, resp)
    @test content == "a,b\n1,2\n"
end
