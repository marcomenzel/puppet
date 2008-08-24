#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/file_serving/content'

describe Puppet::FileServing::Content do
    it "should should be a subclass of Base" do
        Puppet::FileServing::Content.superclass.should equal(Puppet::FileServing::Base)
    end

    it "should indirect file_content" do
        Puppet::FileServing::Content.indirection.name.should == :file_content
    end

    it "should should include the IndirectionHooks module in its indirection" do
        Puppet::FileServing::Content.indirection.metaclass.included_modules.should include(Puppet::FileServing::IndirectionHooks)
    end

    it "should have a method for collecting its attributes" do
        Puppet::FileServing::Content.new("sub/path", :path => "/base").should respond_to(:collect)
    end

    it "should retrieve and store its contents when its attributes are collected" do
        content = Puppet::FileServing::Content.new("sub/path", :path => "/base")

        result = "foo"
        File.stubs(:lstat).returns(stub("stat", :ftype => "file"))
        File.expects(:read).with("/base/sub/path").returns result
        content.collect
        content.content.should equal(result)
    end
end

describe Puppet::FileServing::Content, "when returning the contents" do
    before do
        @path = "/my/base"
        @content = Puppet::FileServing::Content.new("sub/path", :links => :follow, :path => @path)
    end

    it "should fail if the file is a symlink and links are set to :manage" do
        @content.links = :manage
        File.expects(:lstat).with(@path).returns stub("stat", :ftype => "symlink")
        proc { @content.content }.should raise_error(ArgumentError)
    end

    it "should fail if a path is not set" do
        proc { @content.content() }.should raise_error(Errno::ENOENT)
    end

    it "should raise Errno::ENOENT if the file is absent" do
        @content.path = "/there/is/absolutely/no/chance/that/this/path/exists"
        proc { @content.content() }.should raise_error(Errno::ENOENT)
    end

    it "should return the contents of the path if the file exists" do
        File.expects(:stat).with(@path).returns stub("stat", :ftype => "file")
        File.expects(:read).with(@path).returns(:mycontent)
        @content.content.should == :mycontent
    end
end
