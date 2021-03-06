require 'spec_helper'

describe Exam, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe '#upsert' do
    let(:guide) { create(:guide) }
    let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [], organization: 'test'} }
    let!(:exam) { Exam.import_from_json! exam_json }
    context 'when new exam and the guide is the same' do
      let(:guide2) { create(:guide) }
      let(:exam_json2) { {eid: '2', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [], organization: 'test'} }
      let!(:exam2) { Exam.import_from_json! exam_json2 }
      context 'and the organization is the same' do
        it { expect(Exam.count).to eq 1 }
        it { expect(Usage.where(item_id: guide.id, parent_item_id: exam.id).count).to eq 0 }
        it { expect(ExamAuthorization.where(exam_id: exam.id).count).to eq 0 }
      end
    end

  end

  describe '#validate_accessible_for!' do
    context 'not enabled' do
      let(:exam) { create(:exam, start_time: 5.minutes.since, end_time: 10.minutes.since) }

      it { expect(exam.enabled?).to be false }

      context 'not authorized' do
        it { expect { exam.validate_accessible_for! user }.to raise_error(Mumuki::Laboratory::ForbiddenError) }
      end

      context 'authorized' do
        it { expect(exam.enabled?).to be false }
      end
    end

    context 'enabled' do
      let(:exam) { create(:exam, start_time: 5.minutes.ago, end_time: 10.minutes.since) }

      it { expect(exam.enabled?).to be true }

      context 'not authorized' do
        it { expect { exam.validate_accessible_for! user }.to raise_error(Mumuki::Laboratory::ForbiddenError) }
      end

      context 'authorized' do
        before { exam.authorize! user }

        it { expect { exam.validate_accessible_for! user }.to_not raise_error }
        it { expect { exam.validate_accessible_for! other_user }.to raise_error(Mumuki::Laboratory::ForbiddenError) }
      end

      context 'import_from_json' do
        let(:user) { create(:user, uid: 'auth0|1') }
        let(:user2) { create(:user, uid: 'auth0|2') }
        let(:guide) { create(:guide) }
        let(:duration) { 150 }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: duration, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test'} }
        before { Exam.import_from_json! exam_json }

        context 'new exam' do
          it { expect(Exam.count).to eq 1 }
          it { expect { Exam.find_by(classroom_id: '1').validate_accessible_for! user }.to_not raise_error }
          it { expect(guide.usage_in_organization).to be_a Exam }
        end

        context 'new exam, no duration' do
          let(:duration) { nil }
          it { expect(guide.usage_in_organization).to be_a Exam }
        end

        context 'existing exam' do
          let(:exam_json2) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [user2.uid], organization: 'test'} }
          before { Exam.import_from_json! exam_json2 }

          it { expect(Exam.count).to eq 1 }
          it { expect { Exam.find_by(classroom_id: '1').validate_accessible_for! user }.to raise_error(Mumuki::Laboratory::ForbiddenError) }
          it { expect { Exam.find_by(classroom_id: '1').validate_accessible_for! user2 }.to_not raise_error }
        end
      end

      context 'real_end_time' do
        let(:user) { create(:user, uid: 'auth0|1') }
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: duration, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test'} }
        let(:exam) { Exam.import_from_json! exam_json }
        before { exam.start! user }

        context 'with duration' do
          let(:duration) { 150 }
          it { expect(exam.real_end_time user).to eq(exam.end_time) }
          it { expect(exam.started? user).to be_truthy }
        end

        context 'with short duration' do
          let(:duration) { 3 }
          it { expect(exam.real_end_time user).to eq(exam.started_at(user) + 3.minutes) }
          it { expect(exam.started? user).to be_truthy }
        end

        context 'no duration' do
          let(:duration) { nil }
          it { expect(exam.real_end_time user).to eq(exam.end_time) }
          it { expect(exam.started? user).to be_truthy }
        end
      end

      context 'update exam does not change user started_at' do
        let(:user) { create(:user, uid: 'auth0|1') }
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test'} }
        let(:exam) { Exam.import_from_json! exam_json }
        before { exam.start! user }
        before { Exam.import_from_json! exam_json.merge(organization: 'test') }

        it { expect(exam.started?(user)).to be true }

      end

      context 'create exam with non existing user' do
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test'} }
        let(:exam) { Exam.import_from_json! exam_json }

        it { expect { Exam.import_from_json! exam_json.merge(organization: 'test') }.not_to raise_error }

      end

      context 'teacher does not start exams' do
        let(:teacher) { create(:user, uid: 'auth0|1') }
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [], organization: 'test'} }
        let(:exam) { Exam.import_from_json! exam_json }

        context 'exam_authorization do not receive start method' do
          before { expect(teacher).to receive(:teacher_here?).and_return(true) }
          before { expect_any_instance_of(ExamAuthorization).to_not receive(:start!) }
          it { expect { exam.start!(teacher) }.to_not raise_error }

        end

        context 'exam is not started by a teacher' do
          it { expect(exam.started?(teacher)).to be_falsey }
        end

      end
    end
  end
end
