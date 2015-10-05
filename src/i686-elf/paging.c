/* Put this in the header */
/* Functions defined in paging_asm.asm */

extern void load_page_directory(unsigned int* addr);
extern void enable_paging();
/* end */

// Our Paging directory
unsigned int page_directory[1024] __attribute__((aligned(4096)));

// The first page table
unsigned int first_page_table[1024] __attribute__((aligned(4096)));

void paging_install()
{
	// Set up paging directory
	
	// Set each entry to not present
	for(int i = 0; i < 1024; i++)
	{
	    // This sets the following flags to the pages:
	    //   Supervisor: Only kernel-mode can access them
	    //   Write Enabled: It can be both read from and written to
	    //   Not Present: The page table is not present
	    page_directory[i] = 0x00000002;
	}
	
	// Set up 1st paging table
	
	// We will fill all 1024 entries in the table, mapping 4 megabytes
	for(int i = 0; i < 1024; i++)
	{
	    // As the address is page aligned, it will always leave 12 bits zeroed.
	    // Those bits are used by the attributes ;)
	    first_page_table[i] = (i * 0x1000) | 3; // attributes: supervisor level, read/write, present.
	}
	
	// Put the table in our directory
	// Attributes: supervisor level, read/write, present
	page_directory[0] = ((unsigned int)first_page_table) | 3;
	
	load_page_directory(page_directory);
	enable_paging();
}
