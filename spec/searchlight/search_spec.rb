require 'spec_helper'

describe Searchlight::Search do

  let(:search_class) { Named::Class.new('ExampleSearch', described_class) }
  let(:options) { Hash.new }
  let(:search) { search_class.new(options) }

  describe "initializing" do

    let(:options) { {beak_color: 'mauve'} }

    it "mass-assigns provided options" do
      search_class.searches :beak_color
      expect(search.beak_color).to eq('mauve')
    end

    describe "handling invalid options" do

      context "if the option name starts with 'search_'" do

        let(:options) { {search_stink_factor: 4} }

        it "suggests that perhaps you meant to omit that" do
          expect { search }.to raise_error(
            Searchlight::Search::UndefinedOption,
            "No known option called 'search_stink_factor'. Did you just mean 'stink_factor'?"
          )
        end

      end

      context "otherwise" do

        let(:options) { {genus: 'Mellivora'} }

        it "tells you no such option is defined" do
          expect { search }.to raise_error( Searchlight::Search::UndefinedOption, "No known option called 'genus'.")
        end

      end

    end

  end

  describe "search_on" do

    let(:search_target) { "Bobby Fischer" }

    before :each do
      search_class.search_on search_target
    end

    it "makes the object accessible via `search_target`" do
      expect(search_class.search_target).to eq(search_target)
    end

    it "makes the search target available to its children" do
      expect(SpiffyAccountSearch.search_target).to be(MockModel)
    end

    it "allows the children to set their own search target" do
      klass = Class.new(SpiffyAccountSearch) { search_on Array }
      expect(klass.search_target).to be(Array)
      expect(SpiffyAccountSearch.search_target).to be(MockModel)
    end

  end

  describe "search_methods" do

    let(:search_class) {
      Named::Class.new('ExampleSearch', described_class) do
        def search_bees
        end

        def search_bats
        end

        def search_bees
        end
      end
    }

    it "keeps a unique list of the search methods" do
      expect(search.send(:search_methods).map(&:to_s).sort).to eq(['search_bats', 'search_bees'])
    end

  end

  describe "search options" do

    describe "accessors" do

      before :each do
        search_class.searches :foo
        search_class.searches :bar
        search_class.searches :stuff
      end

      it "includes exactly one SearchlightAccessors module for this class" do
        accessors_modules = search_class.ancestors.select {|a| a.name =~ /\ASearchlightAccessors/ }
        expect(accessors_modules.length).to eq(1)
        expect(accessors_modules.first).to be_a(Named::Module)
      end

      it "adds a getter" do
        expect(search).to respond_to(:foo)
      end

      it "adds a setter" do
        expect(search).to respond_to(:foo=)
      end

      it "adds a boolean accessor" do
        expect(search).to respond_to(:foo?)
      end

    end

    describe "accessing search options as booleans" do

      let(:options) { {fishies: fishies} }

      before :each do
        search_class.searches :fishies
      end

      {
        0       => false,
        '0'     => false,
        ''      => false,
        ' '     => false,
        nil     => false,
        'false' => false,
        1       => true,
        '1'     => true,
        15      => true,
        'true'  => true,
        'pie'   => true
      }.each do |input, output|

        describe input.inspect do

          let(:fishies) { input }

          it "becomes boolean #{output}" do
            expect(search.fishies?).to eq(output)
          end

        end

      end

    end

  end

  describe "search" do

    let(:search) { AccountSearch.new }

    it "is initialized with the search_target" do
      expect(search.search).to eq(MockModel)
    end

  end

  describe "results" do

    let(:search) { AccountSearch.new(paid_amount: 50, business_name: "Rod's Meat Shack") }

    it "builds a search by calling all of the methods that had values to search" do
      search.results
      expect(search.search.called_methods).to eq(2.times.map { :where })
    end

    it "returns the search" do
      expect(search.results).to eq(search.search)
    end

    it "only runs the search once" do
      search.should_receive(:run).once.and_call_original
      2.times { search.results }
    end

  end

  describe "run" do

    let(:search_class) {
      Named::Class.new('TinyBs', described_class) do
        search_on Object
        searches :bits, :bats, :bots

        def search_bits; end
        def search_bats; end
        def search_bots; end

      end
    }

    let(:search_instance) { search_class.new(bits: ' ', bats: nil, bots: false) }

    it "only runs search methods that have real values to search on" do
      search_instance.should_not_receive(:search_bits)
      search_instance.should_not_receive(:search_bats)
      search_instance.should_receive(:search_bots)
      search_instance.send(:run)
    end

  end

end
