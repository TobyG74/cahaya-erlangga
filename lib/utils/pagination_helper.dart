import 'package:flutter/material.dart';

mixin PaginationMixin<T extends StatefulWidget, M> on State<T> {
  int currentPage = 1;
  int itemsPerPage = 20;
  int totalItems = 0;
  bool isLoadingMore = false;
  List<M> items = [];
  
  Future<void> loadData();
  
  int get totalPages => (totalItems / itemsPerPage).ceil();
  
  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages || page == currentPage) return;
    
    setState(() {
      currentPage = page;
      isLoadingMore = true;
    });
    
    await loadData();
    
    setState(() {
      isLoadingMore = false;
    });
  }
  
  Future<void> nextPage() async {
    if (currentPage < totalPages) {
      await goToPage(currentPage + 1);
    }
  }
  
  Future<void> previousPage() async {
    if (currentPage > 1) {
      await goToPage(currentPage - 1);
    }
  }
  
  Future<void> firstPage() async {
    await goToPage(1);
  }
  
  Future<void> lastPage() async {
    await goToPage(totalPages);
  }
  
  void resetPagination() {
    setState(() {
      currentPage = 1;
      totalItems = 0;
      items.clear();
    });
  }
  
  int get offset => (currentPage - 1) * itemsPerPage;
  int get limit => itemsPerPage;
  
  Widget buildPaginationControls({Color? primaryColor}) {
    if (totalItems == 0) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final color = primaryColor ?? theme.colorScheme.primary;
    
    List<int> pageNumbers = [];
    if (totalPages <= 5) {
      pageNumbers = List.generate(totalPages, (i) => i + 1);
    } else {
      if (currentPage <= 3) {
        pageNumbers = [1, 2, 3, -1, totalPages];
      } else if (currentPage >= totalPages - 2) {
        pageNumbers = [1, -1, totalPages - 2, totalPages - 1, totalPages];
      } else {
        pageNumbers = [1, -1, currentPage, -1, totalPages];
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Text(
            'Halaman $currentPage dari $totalPages (Total: $totalItems data)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page, size: 18),
                  onPressed: currentPage > 1 ? firstPage : null,
                  tooltip: 'Halaman Pertama',
                  color: color,
                  disabledColor: Colors.grey[400],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Previous page button (<)
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  onPressed: currentPage > 1 ? previousPage : null,
                  tooltip: 'Halaman Sebelumnya',
                  color: color,
                  disabledColor: Colors.grey[400],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 4),
                ...pageNumbers.map((pageNum) {
                  if (pageNum == -1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text('...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    );
                  }
                  
                  final isCurrentPage = pageNum == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: isCurrentPage ? null : () => goToPage(pageNum),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrentPage ? color : Colors.transparent,
                          border: Border.all(
                            color: isCurrentPage ? color : Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$pageNum',
                          style: TextStyle(
                            color: isCurrentPage ? Colors.white : Colors.grey[700],
                            fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                // Next page button (>)
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: currentPage < totalPages ? nextPage : null,
                  tooltip: 'Halaman Berikutnya',
                  color: color,
                  disabledColor: Colors.grey[400],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Last page button (>>)
                IconButton(
                  icon: const Icon(Icons.last_page, size: 18),
                  onPressed: currentPage < totalPages ? lastPage : null,
                  tooltip: 'Halaman Terakhir',
                  color: color,
                  disabledColor: Colors.grey[400],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 8), // Extra space at the end
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Widget untuk menampilkan loading indicator
  Widget buildLoadingIndicator() {
    if (!isLoadingMore) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}