module Test.Fission.Web.Auth.JWT.Validation (tests) where

-- import qualified Fission.Internal.Fixture.Bearer as Fixture
-- import qualified Fission.Web.Auth.JWT.Validation as JWT

import           Test.Fission.Prelude

tests :: SpecWith ()
tests =
  describe "JWT Validation" do
    context "RSA 2048" do
      context "real world bearer token" do
        it "is valid" do
          True `shouldBe` True
          -- FIXME waiting on RSA-PKCS fixture from FE team
          -- JWT.check' Fixture.jwtRSA2048 Fixture.validTime
          --   `shouldBe` Right Fixture.jwtRSA2048
