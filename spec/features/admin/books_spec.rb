#encoding: utf-8
require 'spec_helper'
require_relative "admin_helper"

describe Admin do
  describe Book do

    let!(:borrower) { FactoryGirl.create :borrower }
    let!(:book) { FactoryGirl.create :book }
    let(:borrowed_book) { FactoryGirl.create :book }
    let!(:lending) { FactoryGirl.create :lending, book: borrowed_book }

    before do
      login_as_admin
    end

    describe "Index Page" do
      before do
        visit admin_books_path
      end

      it "displays all books if nothing is searched" do
        Book.limit(10).each do |book|
          expect(page).to have_content(book.titel)
        end
      end

      it "can make new books" do
        expect(page).to have_selector('#new_book_button')
        click_on "new_book_button"
        expect(page).to have_content('Neues Buch')
        fill_in 'book_titel', with: 'Onko der harmonische'
        click_on "submit_book"
        expect(Book.last.titel).to eq 'Onko der harmonische'
      end

      it 'has a working search' do
        fill_in 'search', with: book.titel
        click_on 'search_button'
        expect(page).to have_content(book.titel)
      end

      context 'a lending is overdue' do
        let!(:overdue_book) { FactoryGirl.create :book }
        let!(:overdue_lending) { FactoryGirl.create :overdue_lending, book: overdue_book }

        it 'can extend the return date of a book' do
          fill_in 'search', with: overdue_book.titel
          click_on 'search_button'
          click_on "extend_book_#{overdue_book.id}"
          overdue_book.lendings.overdue.should be_empty
        end
      end

      it "can return a book" do
        fill_in "search", with: borrowed_book.titel
        click_on "search_button"
        click_on "return_book_#{borrowed_book.id}"
        expect(borrowed_book.current_lending).to be_blank
      end

      it "can add a book to collection", :js => true do
        fill_in "search", with: book.titel
        click_on "search_button"
        click_on "add_to_collection_book_#{book.id}"
        page.should have_content("Buch zu Sammlung hinzufügen")
      end

      it "can lend a book", :js => true do
        fill_in "search", with: book.titel
        click_on "search_button"
        page.find("#lend_book_#{book.id}").click
        page.should have_content("Buch verleihen")
        page.click_on "lend_book_button"
        book.current_lending.should be_true
      end

      it "can make a reservation of a book", :js => true do
        # Search for our book
        fill_in "search", with: borrowed_book.titel
        click_on "search_button"

        # Click the reservation link
        click_on "reserve_book_#{borrowed_book.id}"

        # We should get the modal window
        page.should have_content('Buch vormerken')

        # Select a borrower and submit the form
        select borrower.name
        click_on 'reserve_book_button'

        # We should have a reservation now
        borrowed_book.reload
        expect(borrowed_book.reservations.count).to be 1
      end

      it "can destroy a book", :js => false do
        fill_in "search", with: book.titel
        click_on "search_button"
        page.find("#delete_book_#{book.id}").click
        #page.driver.wait_until(page.driver.browser.switch_to.alert.accept)
        #page.driver.browser.switch_to.alert.accept
        expect{Book.find(book.id)}.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should show a book's information and link to print" do
        fill_in "search", with: book.titel
        click_on "search_button"
        page.find("a#book_#{book.id}").click
        page.find("a#book_#{book.id}").click
        page.should have_content "Buch ##{book.id}"
        page.should have_link("Diese Seite drucken")
      end

    end

    describe "Member Page" do
      before do
        visit edit_admin_book_path(book)
      end

      it "displays a single book", :js => false do
        page.should have_content book.titel
      end

      it "can update a book" do
        fill_in "book_titel", with: "Ein neuer Titel"
        click_on "submit_book"
        book.reload
        book.titel.should == "Ein neuer Titel"
      end
    end
  end
end
