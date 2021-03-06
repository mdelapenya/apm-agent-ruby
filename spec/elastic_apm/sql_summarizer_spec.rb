# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require 'spec_helper'

require 'elastic_apm/sql_summarizer'

module ElasticAPM
  RSpec.describe SqlSummarizer do
    it 'summarizes selects from table' do
      result = subject.summarize('SELECT * FROM "table"')
      expect(result).to eq('SELECT FROM table')
    end

    it 'summarizes selects from table with columns' do
      result = subject.summarize('SELECT a, b FROM table')
      expect(result).to eq('SELECT FROM table')
    end

    it 'summarizes selects from table with underscore' do
      result = subject.summarize('SELECT * FROM my_table')
      expect(result).to eq('SELECT FROM my_table')
    end

    it 'simplifies advanced selects' do
      result = subject.summarize("select months.month, count(created_at) from (select DATE '2017-06-09'+(interval '1' month * generate_series(0,11)) as month, DATE '2017-06-10'+(interval '1' month * generate_series(0,11)) as next) months left outer join subscriptions on created_at < month and (soft_destroyed_at IS NULL or soft_destroyed_at >= next) and (suspended_at IS NULL OR suspended_at >= next) group by month order by month desc") # rubocop:disable Layout/LineLength
      expect(result).to eq('SQL')
    end

    it 'summarizes inserts' do
      sql = "INSERT INTO table (a, b) VALUES ('A','B')"
      result = subject.summarize(sql)
      expect(result).to eq('INSERT INTO table')
    end

    it 'summarizes updates' do
      sql = "UPDATE table SET a = 'B' WHERE b = 'B'"
      result = subject.summarize(sql)
      expect(result).to eq('UPDATE table')
    end

    it 'summarizes deletes' do
      result = subject.summarize("DELETE FROM table WHERE b = 'B'")
      expect(result).to eq('DELETE FROM table')
    end

    it 'sumarizes transactions' do
      result = subject.summarize('BEGIN')
      expect(result).to eq('BEGIN')
      result = subject.summarize('COMMIT')
      expect(result).to eq('COMMIT')
    end

    it 'is default when unknown' do
      sql = "SELECT CAST(SERVERPROPERTY('ProductVersion') AS varchar)"
      result = subject.summarize(sql)
      expect(result).to eq 'SQL'
    end

    context 'invalid bytes' do
      it 'replaces invalid bytes' do
        sql = "INSERT INTO table (a, b) VALUES ('\255','\255')"
        result = subject.summarize(sql)
        expect(result).to eq('INSERT INTO table')
      end
    end
  end
end
