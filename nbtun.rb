#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'yaml'
require 'resolv'
require 'dotenv/load'

require_relative 'lib/api-netbox.rb'
require_relative 'lib/nbtun.rb'

nbtun = NbtUn.new
nbtun.main_loop
