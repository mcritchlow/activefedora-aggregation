require 'spec_helper'

describe "Filtering" do
  before do
    class Image < ActiveFedora::Base
      aggregates :members, class_name: "ActiveFedora::Base"

      filters_association :members, as: :child_objects, condition: :pcdm_object?
      filters_association :members, as: :child_collections, condition: :pcdm_collection?
    end

    class TestObject < ActiveFedora::Base
      def pcdm_object?
        true
      end

      def pcdm_collection?
        false
      end
    end

    class TestCollection < ActiveFedora::Base
      def pcdm_object?
        false
      end

      def pcdm_collection?
        true
      end
    end
  end

  after do
    Object.send(:remove_const, :Image)
    Object.send(:remove_const, :TestObject)
    Object.send(:remove_const, :TestCollection)
  end

  let(:image) { Image.new }
  let(:test_object) { TestObject.new }
  let(:test_collection) { TestCollection.new }

  describe "setting" do
    context "when an incorrect object type is sent" do
      it "raises an error" do
        expect { image.child_collections = [test_object] }.to raise_error ArgumentError
      end
    end

    context "when the parent is already loaded" do
      let(:another_collection) { TestCollection.new }
      before do
        image.members = [test_object, test_collection]
        image.child_collections = [another_collection]
      end
      it "overwrites existing matches" do
        expect(image.members).to eq [test_object, another_collection]
      end
    end
  end

  describe "appending" do
    context "when an incorrect object type is sent" do
      it "raises an error" do
        expect { image.child_collections << test_object }.to raise_error ArgumentError
      end
    end

    context "when the parent is already loaded" do
      let(:another_collection) { TestCollection.new }
      before do
        image.members = [test_object, test_collection]
        image.child_collections << [another_collection]
      end

      it "updates the parent" do
        expect(image.members).to eq [test_object, test_collection, another_collection]
      end
    end
  end

  describe "reading" do
    before do
      image.members = [test_object, test_collection]
    end

    it "returns the objects of the correct type" do
      expect(image.child_objects).to eq [test_object]
    end
  end

  describe "when the parent association is changed" do
    before do
      image.child_objects = [test_object]
      image.members = [test_collection]
    end

    it "updates the filtered relation" do
      expect(image.child_objects).to eq []
    end
  end
end
